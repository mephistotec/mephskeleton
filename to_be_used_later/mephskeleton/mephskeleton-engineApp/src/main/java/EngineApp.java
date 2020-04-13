import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.context.annotation.Configuration;

@EnableAsync
@EnableCaching
@SpringBootApplication
@Configuration
public class EngineApp {
    public static void main(final String[] args) {

        SpringApplication.run(EngineApp.class, args);
    }
}
