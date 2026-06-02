package capstone.ai_meal_assistant_batch.global.s3;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.CopyObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectResponse;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

@Slf4j
@Service
@RequiredArgsConstructor
public class S3ImageUploadService {

    private final S3Client s3Client;

    @Value("${cloud.aws.s3.bucket}")
    private String bucket;

    @Value("${cloud.aws.region.static}")
    private String region;

    @Value("${cloud.aws.s3.cloudfront-domain:}")
    private String cloudfrontDomain;

    private static final int CONNECT_TIMEOUT_MS = 10_000;
    private static final int READ_TIMEOUT_MS = 30_000;
    private static final int MAX_REDIRECTS = 5;
    // HTML 에러 페이지/리다이렉트 안내 페이지는 보통 이보다 작음 — 정상 이미지 최소 크기 가드
    private static final long MIN_VALID_IMAGE_SIZE = 512L;

    /**
     * 원본 URL에서 이미지를 다운로드해 S3에 업로드하고 S3 URL을 반환한다.
     * 응답 상태/Content-Type/매직 바이트를 검증해 손상된 파일이 S3에 올라가지 않도록 한다.
     * S3에 이미 정상 파일이 있으면 스킵하고, 비정상이면 재업로드한다.
     * 다운로드/업로드 실패 시 원본 URL을 반환한다.
     */
    public String uploadFromUrl(String originalUrl) {
        return uploadFromUrl(originalUrl, null);
    }

    /**
     * {@link #uploadFromUrl(String)}와 동일하되, S3 key를 foodCode 기반으로 생성한다.
     * foodCode가 비어 있으면 원본 URL 해시로 폴백한다. ({@link #buildObjectKey})
     */
    public String uploadFromUrl(String originalUrl, String foodCode) {
        if (originalUrl == null || originalUrl.isBlank()) {
            return originalUrl;
        }
        if (isOurStorageUrl(originalUrl)) {
            return originalUrl;
        }

        String key = buildObjectKey(foodCode, originalUrl);

        if (existsValidInS3(key)) {
            log.debug("S3 이미 존재(정상), 스킵: {}", key);
            return buildS3Url(key);
        }

        try {
            DownloadedImage image = downloadImage(originalUrl);
            s3Client.putObject(
                    PutObjectRequest.builder()
                            .bucket(bucket)
                            .key(key)
                            .contentType(image.contentType)
                            .contentLength((long) image.bytes.length)
                            .build(),
                    RequestBody.fromBytes(image.bytes)
            );
            log.info("S3 업로드 성공: {} (size={} bytes, contentType={})",
                    key, image.bytes.length, image.contentType);
            return buildS3Url(key);
        } catch (Exception e) {
            log.warn("S3 업로드 실패, 원본 URL 사용: {} | 원인: {}", originalUrl, e.getMessage());
            return originalUrl;
        }
    }

    /**
     * 주어진 URL(S3 직링크 또는 CloudFront)이 가리키는 S3 객체가 유효한 이미지인지 확인한다.
     * (HEAD 1회로 contentType/size를 검사.)
     */
    public boolean isS3UrlValid(String url) {
        String key = extractS3Key(url);
        if (key == null || key.isBlank()) return false;
        return existsValidInS3(key);
    }

    /**
     * 우리 스토리지(S3 직링크 또는 설정된 CloudFront 도메인)에 속한 URL인지 판별.
     */
    public boolean isOurStorageUrl(String url) {
        if (url == null || url.isBlank()) return false;
        if (url.contains("amazonaws.com")) return true;
        if (cloudfrontDomain != null && !cloudfrontDomain.isBlank() && url.contains(cloudfrontDomain)) return true;
        return false;
    }

    /**
     * URL → S3 key. amazonaws.com과 cloudfront 도메인 모두 지원. 매칭 안 되면 null.
     */
    private String extractS3Key(String url) {
        if (url == null || url.isBlank()) return null;
        if (cloudfrontDomain != null && !cloudfrontDomain.isBlank()) {
            int idx = url.indexOf(cloudfrontDomain);
            if (idx >= 0) {
                int start = idx + cloudfrontDomain.length();
                if (start < url.length() && url.charAt(start) == '/') {
                    return url.substring(start + 1);
                }
            }
        }
        int idx = url.indexOf(".amazonaws.com/");
        if (idx >= 0) {
            return url.substring(idx + ".amazonaws.com/".length());
        }
        return null;
    }

    private DownloadedImage downloadImage(String originalUrl) throws IOException {
        String currentUrl = originalUrl;
        for (int hop = 0; hop < MAX_REDIRECTS; hop++) {
            HttpURLConnection conn = (HttpURLConnection) URI.create(currentUrl).toURL().openConnection();
            // 성공/리다이렉트/에러 모든 경로에서 소켓이 정리되도록 finally 에서 disconnect.
            try {
                conn.setConnectTimeout(CONNECT_TIMEOUT_MS);
                conn.setReadTimeout(READ_TIMEOUT_MS);
                conn.setRequestMethod("GET");
                conn.setRequestProperty("User-Agent", "Mozilla/5.0 (compatible; NUTRIAgentBatch/1.0)");
                conn.setRequestProperty("Accept", "image/*,*/*;q=0.8");
                // http↔https 간 리다이렉트는 기본 false라 직접 추적
                conn.setInstanceFollowRedirects(false);

                int code = conn.getResponseCode();
                if (code >= 300 && code < 400) {
                    String location = conn.getHeaderField("Location");
                    if (location == null || location.isBlank()) {
                        throw new IOException("리다이렉트 응답에 Location 헤더 없음 (status=" + code + ")");
                    }
                    currentUrl = URI.create(currentUrl).resolve(location).toString();
                    continue;
                }
                if (code < 200 || code >= 300) {
                    throw new IOException("HTTP " + code + " " + currentUrl);
                }

                String responseContentType = conn.getContentType();
                try (InputStream is = conn.getInputStream()) {
                    byte[] bytes = is.readAllBytes();
                    if (bytes.length < MIN_VALID_IMAGE_SIZE) {
                        throw new IOException("응답 본문이 비정상적으로 작음 (size=" + bytes.length + ")");
                    }
                    String contentType = resolveContentType(responseContentType, currentUrl, bytes);
                    if (!contentType.startsWith("image/")) {
                        throw new IOException("응답이 이미지가 아님 (header contentType=" + responseContentType + ")");
                    }
                    if (!hasImageMagicBytes(bytes)) {
                        throw new IOException("유효한 이미지 매직 바이트가 아님 (앞 4바이트=" + previewHex(bytes) + ")");
                    }
                    return new DownloadedImage(bytes, contentType);
                }
            } finally {
                conn.disconnect();
            }
        }
        throw new IOException("리다이렉트 최대 " + MAX_REDIRECTS + "회 초과: " + originalUrl);
    }

    /**
     * S3에 이미 객체가 있더라도 contentType이 image/* 가 아니거나 크기가 비정상이면
     * 손상된 것으로 보고 미존재로 간주해 재업로드를 유도한다.
     */
    private boolean existsValidInS3(String key) {
        try {
            HeadObjectResponse head = s3Client.headObject(
                    HeadObjectRequest.builder().bucket(bucket).key(key).build());
            String ct = head.contentType();
            Long size = head.contentLength();
            boolean validType = ct != null && ct.toLowerCase().startsWith("image/");
            boolean validSize = size != null && size >= MIN_VALID_IMAGE_SIZE;
            if (!validType || !validSize) {
                log.info("S3 객체 비정상 판단, 재업로드 진행: key={}, contentType={}, size={}",
                        key, ct, size);
                return false;
            }
            return true;
        } catch (NoSuchKeyException e) {
            return false;
        } catch (Exception e) {
            log.warn("S3 HeadObject 실패, 미존재로 간주: key={}, 원인={}", key, e.getMessage());
            return false;
        }
    }

    private String resolveContentType(String headerContentType, String url, byte[] bytes) {
        if (headerContentType != null) {
            String trimmed = headerContentType.toLowerCase();
            int semi = trimmed.indexOf(';');
            if (semi > 0) trimmed = trimmed.substring(0, semi).trim();
            if (trimmed.startsWith("image/")) {
                return trimmed;
            }
        }
        String fromMagic = guessFromMagicBytes(bytes);
        if (fromMagic != null) return fromMagic;

        String lower = url.toLowerCase();
        int q = lower.indexOf('?');
        if (q > 0) lower = lower.substring(0, q);
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
        if (lower.endsWith(".png")) return "image/png";
        if (lower.endsWith(".gif")) return "image/gif";
        if (lower.endsWith(".webp")) return "image/webp";
        return "application/octet-stream";
    }

    private String guessFromMagicBytes(byte[] b) {
        if (b == null || b.length < 4) return null;
        if ((b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) return "image/jpeg";
        if ((b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G') return "image/png";
        if (b[0] == 'G' && b[1] == 'I' && b[2] == 'F') return "image/gif";
        if (b.length >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') return "image/webp";
        return null;
    }

    private boolean hasImageMagicBytes(byte[] b) {
        return guessFromMagicBytes(b) != null;
    }

    private String previewHex(byte[] b) {
        int n = Math.min(4, b.length);
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < n; i++) sb.append(String.format("%02X ", b[i] & 0xFF));
        return sb.toString().trim();
    }

    private String buildS3Url(String key) {
        if (cloudfrontDomain != null && !cloudfrontDomain.isBlank()) {
            return "https://" + cloudfrontDomain + "/" + key;
        }
        return "https://" + bucket + ".s3." + region + ".amazonaws.com/" + key;
    }

    /**
     * S3 객체 key를 생성한다.
     * <p>업무 식별자인 foodCode 기반(예: {@code images/food/10_00028})을 우선 사용한다.
     * URL-safe(특수문자 없음)하고 메뉴당 유일하므로 쿼리스트링이 key에 섞여 들어가
     * URL이 깨지는 문제를 원천 차단한다. foodCode가 없으면 원본 URL 해시로 폴백한다.
     * <p>확장자는 붙이지 않는다 — 렌더링은 업로드 시 저장한 Content-Type 메타데이터로 결정된다.
     */
    private String buildObjectKey(String foodCode, String originalUrl) {
        if (foodCode != null && !foodCode.isBlank()) {
            return "images/food/" + foodCode;
        }
        return "images/food/" + sha256Hex(originalUrl);
    }

    private String sha256Hex(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(input.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            // SHA-256은 모든 JVM에 존재하므로 사실상 도달 불가.
            throw new IllegalStateException("SHA-256 알고리즘 사용 불가", e);
        }
    }

    /**
     * 원본 재다운로드 없이 S3 내부에서 oldKey → newKey 로 객체를 복사(재키잉)한다.
     * 이미 S3에 정상 사본이 있는 경우(예: 쿼리스트링이 박힌 깨진 key) 안전하게 재정렬할 때 사용한다.
     *
     * @return 성공 시 newKey의 접근 URL, 실패/불필요 시 처리 결과 URL. 복사 실패 시 null.
     */
    public String reKeyWithinS3(String oldKey, String newKey) {
        if (oldKey == null || oldKey.isBlank() || newKey == null || newKey.isBlank()) {
            return null;
        }
        if (oldKey.equals(newKey)) {
            return buildS3Url(newKey);
        }
        try {
            s3Client.copyObject(CopyObjectRequest.builder()
                    .sourceBucket(bucket)
                    .sourceKey(oldKey)
                    .destinationBucket(bucket)
                    .destinationKey(newKey)
                    .build());
            log.info("S3 재키잉 성공: {} -> {}", oldKey, newKey);
            return buildS3Url(newKey);
        } catch (Exception e) {
            log.warn("S3 재키잉 실패: {} -> {} | 원인: {}", oldKey, newKey, e.getMessage());
            return null;
        }
    }

    /** foodCode/원본 URL로 생성될 S3 key를 외부에서 조회한다. ({@link #buildObjectKey} 노출) */
    public String objectKeyFor(String foodCode, String originalUrl) {
        return buildObjectKey(foodCode, originalUrl);
    }

    /** S3 key로부터 접근 URL을 만든다. ({@link #buildS3Url} 노출) */
    public String urlForKey(String key) {
        return buildS3Url(key);
    }

    /** URL에서 S3 key를 추출한다. 매칭 안 되면 null. ({@link #extractS3Key} 노출) */
    public String s3KeyOf(String url) {
        return extractS3Key(url);
    }

    /** 주어진 key의 S3 객체가 유효한 이미지로 존재하는지 확인한다. ({@link #existsValidInS3} 노출) */
    public boolean existsInS3(String key) {
        return existsValidInS3(key);
    }

    /**
     * amazonaws.com URL을 CloudFront URL로 치환. CloudFront 도메인이 비어있으면 원본을 그대로 반환.
     */
    public String toCloudFrontUrl(String url) {
        if (url == null || url.isBlank()) return url;
        if (cloudfrontDomain == null || cloudfrontDomain.isBlank()) return url;
        String key = extractS3Key(url);
        if (key == null || key.isBlank()) return url;
        return "https://" + cloudfrontDomain + "/" + key;
    }

    private static class DownloadedImage {
        final byte[] bytes;
        final String contentType;
        DownloadedImage(byte[] bytes, String contentType) {
            this.bytes = bytes;
            this.contentType = contentType;
        }
    }
}
