package capstone.ai_meal_assistant_backend.global.mail;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

// 텍스트 메일 발송 공통 서비스 (Gmail SMTP — 계정은 환경변수 MAIL_USERNAME/MAIL_PASSWORD)
@Slf4j
@Service
public class MailService {

    private final JavaMailSender mailSender;
    private final String fromAddress;

    public MailService(JavaMailSender mailSender,
                       @Value("${spring.mail.username:}") String fromAddress) {
        this.mailSender = mailSender;
        this.fromAddress = fromAddress;
    }

    // 발송 성공 여부 반환 — 실패해도 예외를 전파하지 않고 호출부에서 사용자 안내
    public boolean send(String to, String subject, String text) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            if (!fromAddress.isBlank()) {
                message.setFrom(fromAddress);
            }
            message.setTo(to);
            message.setSubject(subject);
            message.setText(text);
            mailSender.send(message);
            return true;
        } catch (MailException e) {
            log.error("메일 발송 실패: to={}", to, e);
            return false;
        }
    }
}
