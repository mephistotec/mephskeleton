import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.context.annotation.Configuration;


import com.ulisesbocchio.jasyptspringboot.annotation.EnableEncryptableProperties;

@EnableAsync
@EnableCaching
@SpringBootApplication
@EnableEncryptableProperties
@Configuration
public class EngineApp {
    public static void main(final String[] args) {

        SpringApplication.run(EngineApp.class, args);
    }
}
