package org.mango.mail;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableAsync;

import com.ulisesbocchio.jasyptspringboot.annotation.EnableEncryptableProperties;

/**
 * Aplicación SpringBoot de consumo de colas SQS.
 *
 */
@EnableAsync
@EnableCaching
@SpringBootApplication
@EnableEncryptableProperties
public class EngineAndRestAPIApp extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(final SpringApplicationBuilder application) {
        return application.sources(EngineAndRestAPIApp.class);
    }

    /**
     * Inicio app SpringBoot consumo de colas SQS.
     *
     * @param args
     *            Parametros main.
     *
     */
    public static void main(final String[] args) {
        SpringApplication.run(EngineAndRestAPIApp.class, args);
    }
}
