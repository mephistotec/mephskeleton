package org.mango.mail;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Configuration;


import com.ulisesbocchio.jasyptspringboot.annotation.EnableEncryptableProperties;

@SpringBootApplication
@EnableCaching
@EnableEncryptableProperties
@Configuration
public class RESTApp {
    public static void main(final String[] args) {
        SpringApplication.run(RESTApp.class, args);
    }
}
