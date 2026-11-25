package com.sms.backend.bootstrap;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

class DemoProvisionerTests {
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(4);

    @Test
    void validatesRoleSpecificPasswordLengthsAndAllowedCharacters() {
        assertDoesNotThrow(() -> DemoProvisioner.validatePassword("ctsv_demo", "CtSv2026"));
        assertDoesNotThrow(() -> DemoProvisioner.validatePassword("principal", "Principal2026!"));
        assertThrows(
                IllegalStateException.class,
                () -> DemoProvisioner.validatePassword("ctsv_demo", "short"));
        assertThrows(
                IllegalStateException.class,
                () -> DemoProvisioner.validatePassword("principal", "Short2026!"));
        assertThrows(
                IllegalStateException.class,
                () -> DemoProvisioner.validatePassword("principal", "Has space 2026!"));
        assertThrows(
                IllegalStateException.class,
                () -> DemoProvisioner.validatePassword("principal", "A".repeat(73)));
        assertThrows(
                IllegalStateException.class,
                () -> DemoProvisioner.validatePassword("principal", null));
    }

    @Test
    void activeAccountsAreVerifiedAndNeverOverwritten() {
        String hash = encoder.encode("OriginalPassword2026!");
        for (boolean initialize : new boolean[] {false, true}) {
            assertFalse(DemoProvisioner.shouldUpdatePassword(
                    "ctsv_demo", true, "OriginalPassword2026!", hash, initialize, encoder));
            assertThrows(IllegalStateException.class, () -> DemoProvisioner.shouldUpdatePassword(
                    "ctsv_demo", true, "NewPassword2026!", hash, initialize, encoder));
        }
    }

    @Test
    void onlyTheExactDisabledSeedCanBeActivatedDuringInitialization() {
        String realHash = encoder.encode("OriginalPassword2026!");
        assertTrue(DemoProvisioner.shouldUpdatePassword(
                "ctsv_demo", false, "NewPassword2026!", "!ACCOUNT_DISABLED", true, encoder));
        assertThrows(IllegalStateException.class, () -> DemoProvisioner.shouldUpdatePassword(
                "ctsv_demo", false, "NewPassword2026!", "!ACCOUNT_DISABLED", false, encoder));
        assertThrows(IllegalStateException.class, () -> DemoProvisioner.shouldUpdatePassword(
                "ctsv_demo", false, "OriginalPassword2026!", realHash, true, encoder));
        assertThrows(IllegalStateException.class, () -> DemoProvisioner.shouldUpdatePassword(
                "principal", false, "NewPassword2026!", "!ACCOUNT_DISABLED", true, encoder));
    }
}
