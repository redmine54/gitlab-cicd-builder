package example;

import static org.junit.jupiter.api.Assertions.assertEquals;
import org.junit.jupiter.api.Test;

class HealthServletTest {
    @Test
    void healthEndpointUsesExpectedPath() {
        assertEquals("/health", HealthServlet.class.getAnnotation(jakarta.servlet.annotation.WebServlet.class).value()[0]);
    }
}
