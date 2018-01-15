package com.fasteque.streaming.controller.configuration;

import com.fasteque.streaming.controller.ApiController;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import springfox.documentation.builders.PathSelectors;
import springfox.documentation.service.ApiInfo;
import springfox.documentation.service.Contact;
import springfox.documentation.spi.DocumentationType;
import springfox.documentation.spring.web.plugins.Docket;
import springfox.documentation.swagger2.annotations.EnableSwagger2;

import static springfox.documentation.builders.RequestHandlerSelectors.withClassAnnotation;

@Configuration
@EnableSwagger2
public class SwaggerConfiguration {
//    @Bean
//    public Docket api() {
//        return new Docket(DocumentationType.SWAGGER_12)
//                .select()
//                .apis(withClassAnnotation(ApiController.class))
//                .paths(PathSelectors.any())
//                .build()
//                .apiInfo(apiInfo());
//    }
//
//    private ApiInfo apiInfo() {
//        ApiInfo apiInfo = new ApiInfo(
//                "FFMpeg REST API",
//                "Experimental/demo REST Api documentation",
//                "1.0",
//                "Just try",
//                new Contact("", "", ""),
//                null,
//                null,
//                null);
//        return apiInfo;
//    }
}
