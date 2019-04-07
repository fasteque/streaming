package com.fasteque.streaming.config.security;

import com.fasteque.streaming.config.properties.BasicAuthenticationCredentials;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.authentication.www.BasicAuthenticationEntryPoint;


@Configuration
@EnableWebSecurity
public class BasicAuthenticationWebSecurityConfigurerAdapter extends WebSecurityConfigurerAdapter {

    @Autowired
    private AuthenticationEntryPoint authEntryPoint;

    @Autowired
    private BasicAuthenticationCredentials basicAuthenticationCredentials;

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable()
                .authorizeRequests()
                .anyRequest()
                .authenticated()
                .and()
                .httpBasic()
                .authenticationEntryPoint(authEntryPoint);
    }

    @Autowired
    public void configureGlobal(final AuthenticationManagerBuilder auth) throws Exception {
//        System.out.println(new BCryptPasswordEncoder().encode(PASSWORD_IN_CLEAR));
        auth.inMemoryAuthentication()
                .passwordEncoder(passwordEncoder())
                .withUser(basicAuthenticationCredentials.getName())
                .password(basicAuthenticationCredentials.getPassword())
                .authorities("ROLE_USER", "ROLE_ADMIN");
    }

    /*
        Access-denied exception is handled by the ExceptionTranslationFilter.
        the filter then delegates to a particular implementation strategy of
        the AuthenticationEntryPoint interface.

        By writing directly to the HTTP Response we now have full control over
        the format of the response body, which is an HTML page by default.
     */
    @Bean
    public AuthenticationEntryPoint authenticationEntryPoint() {
        final BasicAuthenticationEntryPoint entryPoint = new BasicAuthenticationEntryPoint();
        entryPoint.setRealmName("swisscom-streaming-realm");
        return entryPoint;
    }

    private PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
