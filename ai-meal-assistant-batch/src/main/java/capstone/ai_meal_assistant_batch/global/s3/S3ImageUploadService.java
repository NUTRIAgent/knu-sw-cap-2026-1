package capstone.ai_meal_assistant_batch.global.s3;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.InputStream;
import java.net.URI;
import java.net.URL;

@Slf4j
@Service
@RequiredArgsConstructor
public class S3ImageUploadService {

    private final S3Client s3Client;

    @Value("${cloud.aws.s3.bucket}")
    private String bucket;

    @Value("${cloud.aws.region.static}")
    private String region;

    /**
     * 원본 URL에서 이미지를 다운로드해 S3에 업로드하고 S3 URL을 반환한다.
     * 빈 URL이면 그대로, 업로드 실패 시 원본 URL을 반환한다.
     */
    public String uploadFromUrl(String originalUrl) {
        if (originalUrl == null || originalUrl.isBlank()) {
            return originalUrl;
        }
        if (originalUrl.contains("amazonaws.com")) {
            return originalUrl;
        }

        String fileName = originalUrl.substring(originalUrl.lastIndexOf('/') + 1);
        String key = "images/food/" + fileName;

        if (existsInS3(key)) {
            log.debug("S3 이미 존재, 스킵: {}", key);
            return buildS3Url(key);
        }

        try {
            URL url = URI.create(originalUrl).toURL();
            try (InputStream is = url.openStream()) {
                byte[] bytes = is.readAllBytes();
                String contentType = originalUrl.endsWith(".jpg") || originalUrl.endsWith(".jpeg")
                        ? "image/jpeg" : "image/png";
                s3Client.putObject(
                        PutObjectRequest.builder()
                                .bucket(bucket)
                                .key(key)
                                .contentType(contentType)
                                .build(),
                        RequestBody.fromBytes(bytes)
                );
                log.info("S3 업로드 성공: {}", key);
                return buildS3Url(key);
            }
        } catch (Exception e) {
            log.warn("S3 업로드 실패, 원본 URL 사용: {} | 원인: {}", originalUrl, e.getMessage());
            return originalUrl;
        }
    }

    private boolean existsInS3(String key) {
        try {
            s3Client.headObject(HeadObjectRequest.builder().bucket(bucket).key(key).build());
            return true;
        } catch (NoSuchKeyException e) {
            return false;
        } catch (Exception e) {
            return false;
        }
    }

    private String buildS3Url(String key) {
        return "https://" + bucket + ".s3." + region + ".amazonaws.com/" + key;
    }
}
