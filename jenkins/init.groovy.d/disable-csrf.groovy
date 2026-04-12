import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

// Disable CSRF
instance.setCrumbIssuer(null)

// Set up weak credentials: admin:admin
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin")
instance.setSecurityRealm(hudsonRealm)

// Allow anonymous read access (needed for CVE-2024-23897 exploitation)
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(true)
instance.setAuthorizationStrategy(strategy)

instance.save()

println "[+] Jenkins configured: admin:admin, CSRF disabled, anonymous read enabled"
