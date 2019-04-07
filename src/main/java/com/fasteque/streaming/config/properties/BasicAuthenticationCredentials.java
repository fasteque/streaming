package com.fasteque.streaming.config.properties;


import org.hibernate.validator.constraints.Length;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

@Configuration
@ConfigurationProperties(prefix = "streaming.security.user")
public class BasicAuthenticationCredentials {

    @NotBlank
    @Length(min = 4)
    private String name;
    @NotBlank
    @Pattern(regexp = "^\\$2[ayb]\\$.{56}$")
    private String password;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}
