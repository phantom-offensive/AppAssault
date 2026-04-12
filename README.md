# AppAssault Lab — Attacking Common Applications

```
    ╔══════════════════════════════════════════╗
    ║                                          ║
    ║   APP ASSAULT LAB                        ║
    ║   Attacking Common Applications          ║
    ║                                          ║
    ║   11 Vulnerable Apps | 11 CVEs           ║
    ║   325 Points | Real Exploits             ║
    ║                                          ║
    ╚══════════════════════════════════════════╝
```

**A collection of intentionally vulnerable real-world applications for practicing exploitation techniques.**

Each application runs a specific vulnerable version with known CVEs and misconfigurations. Enumerate, exploit, and capture the flag from each target.

---

## Quick Start

```bash
git clone https://github.com/phantom-offensive/AppAssault.git
cd AppAssault
cp .env.example .env    # Customize flags/passwords or use defaults
docker compose up -d

# Wait 3-5 minutes for all services to initialize
# Open scoreboard: http://localhost:9099
```

### Requirements
- Docker + Docker Compose
- 8GB+ RAM (recommended 16GB)
- Kali Linux or equivalent pentest OS

---

## Targets

| # | Target | Category | Port | Points | Difficulty |
|---|--------|----------|------|--------|------------|
| 1 | WordPress | CMS | 9001 | 20 | Easy |
| 2 | Joomla | CMS | 9002 | 20 | Easy |
| 3 | Gitea | DevOps | 9003 | 25 | Medium |
| 4 | Tomcat | Servlet | 9004/9009 | 30 | Medium |
| 5 | Jenkins | DevOps | 9005 | 30 | Medium |
| 6 | GitLab CE | DevOps | 9006 | 40 | Hard |
| 7 | Splunk | Monitoring | 9007 | 30 | Medium |
| 8 | Apache | CGI | 9012 | 25 | Medium |
| 9 | Bash/CGI | CGI | 9013 | 20 | Easy |
| 10 | phpMyAdmin | Data | 9014 | 35 | Hard |
| 11 | OpenLDAP | Data | 9015 | 15 | Easy |

**Total: 325 points** | **Scoreboard: http://localhost:9099**

---

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  appnet — 10.30.10.0/24                                     │
│                                                             │
│  CMS                        DevOps                          │
│  ├─ wordpress  10.30.10.10  ├─ tomcat   10.30.10.40         │
│  ├─ joomla     10.30.10.20  ├─ jenkins  10.30.10.50         │
│  │                          ├─ gitlab   10.30.10.60         │
│  Source Control              │                               │
│  ├─ gitea      10.30.10.30  Monitoring                      │
│  │                          ├─ splunk   10.30.10.70         │
│  CGI/Legacy                                                 │
│  ├─ apache-cgi 10.30.10.80  Data & Services                │
│  ├─ shellshock 10.30.10.81  ├─ phpmyadmin 10.30.10.90      │
│  │                          ├─ openldap   10.30.10.100     │
│  Scoreboard                                                 │
│  └─ scoreboard 10.30.10.200                                │
└─────────────────────────────────────────────────────────────┘
```

---

---

## Attack Methodology

For each target:

1. **Discovery** — Port scan, service identification, version detection
2. **Enumeration** — Application-specific enumeration (WPScan, droopescan, etc.)
3. **Exploitation** — Exploit the CVE or misconfiguration
4. **Post-Exploitation** — Read the flag, demonstrate impact
5. **Submit** — Submit flags to scoreboard at http://localhost:9099

---

## Recommended Tools

- [nmap](https://nmap.org/) — Service discovery and version detection
- [WPScan](https://github.com/wpscanteam/wpscan) — WordPress vulnerability scanner
- [Metasploit](https://www.metasploit.com/) — Exploit framework
- [Burp Suite](https://portswigger.net/burp) — Web proxy
- [curl](https://curl.se/) — HTTP client
- [searchsploit](https://www.exploit-db.com/searchsploit) — Exploit database search
- [nuclei](https://github.com/projectdiscovery/nuclei) — Vulnerability scanner
- [pyfuscation](https://github.com/CBHue/PyFuscation) — AJP exploit tools (Ghostcat)

---

## Flag Submission

```bash
# Via scoreboard UI
open http://localhost:9099

# Via API
curl -X POST http://localhost:9099/api/submit \
  -H "Content-Type: application/json" \
  -d '{"flag":"FLAG{...}"}'
```

---

## Disclaimer

**All applications are intentionally vulnerable.** Do NOT expose to the internet. Run locally or in an isolated network for training only.

---

## Author

**Opeyemi Kolawole** — [GitHub](https://github.com/phantom-offensive)

## License

BSD 3-Clause
