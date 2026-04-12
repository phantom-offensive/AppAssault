from flask import Flask, request, render_template_string, jsonify
import hashlib
import sqlite3
import os
from datetime import datetime

app = Flask(__name__)
DB_PATH = "/app/scoreboard.db"

# Read flags from environment variables — no hardcoded values
FLAG_DEFS = [
    {"id": 1, "name": "Blog Platform", "category": "CMS", "points": 20, "difficulty": "Easy",
     "env": "FLAG_WORDPRESS", "hint": "Explore the application", "port": "9001"},
    {"id": 2, "name": "Content Manager", "category": "CMS", "points": 20, "difficulty": "Easy",
     "env": "FLAG_JOOMLA", "hint": "Not everything should be public", "port": "9002"},
    {"id": 3, "name": "Code Repository", "category": "DevOps", "points": 25, "difficulty": "Medium",
     "env": "FLAG_GITEA", "hint": "What happens when you push?", "port": "9003"},
    {"id": 4, "name": "App Server", "category": "Servlet", "points": 30, "difficulty": "Medium",
     "env": "FLAG_TOMCAT", "hint": "Some doors are less visible", "port": "9004"},
    {"id": 5, "name": "CI/CD Pipeline", "category": "DevOps", "points": 30, "difficulty": "Medium",
     "env": "FLAG_JENKINS", "hint": "Automation has its risks", "port": "9005"},
    {"id": 6, "name": "Source Control Platform", "category": "DevOps", "points": 40, "difficulty": "Hard",
     "env": "FLAG_GITLAB", "hint": "Not everything is as it appears", "port": "9006"},
    {"id": 7, "name": "Log Aggregator", "category": "Monitoring", "points": 30, "difficulty": "Medium",
     "env": "FLAG_SPLUNK", "hint": "Did anyone change the locks?", "port": "9007"},
    {"id": 8, "name": "Legacy Web Server", "category": "CGI", "points": 25, "difficulty": "Medium",
     "env": "FLAG_APACHE", "hint": "Sometimes the path isn't what it seems", "port": "9012"},
    {"id": 9, "name": "Legacy CGI Server", "category": "CGI", "points": 20, "difficulty": "Easy",
     "env": "FLAG_SHELLSHOCK", "hint": "Old habits die hard", "port": "9013"},
    {"id": 10, "name": "Database Manager", "category": "Data", "points": 35, "difficulty": "Hard",
     "env": "FLAG_PHPMYADMIN", "hint": "Management tools need managing", "port": "9014"},
    {"id": 11, "name": "Directory Service", "category": "Data", "points": 15, "difficulty": "Easy",
     "env": "FLAG_LDAP", "hint": "Who needs credentials anyway?", "port": "9015"},
]

FLAGS = []
for f in FLAG_DEFS:
    val = os.environ.get(f["env"], "")
    entry = {k: v for k, v in f.items() if k != "env"}
    entry["hash"] = hashlib.sha256(val.encode()).hexdigest() if val else ""
    FLAGS.append(entry)

TOTAL_POINTS = sum(f["points"] for f in FLAGS)

def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""CREATE TABLE IF NOT EXISTS submissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        flag_id INTEGER, flag_name TEXT, points INTEGER,
        submitted_at TEXT, captured INTEGER DEFAULT 0
    )""")
    conn.commit()
    conn.close()

init_db()

HTML = """<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>AppAssault Lab</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0a0e1a;color:#e8ecf4;font-family:'Segoe UI',sans-serif;font-size:13px}
.nav{background:#111827;border-bottom:1px solid #1f2937;padding:12px 24px;display:flex;justify-content:space-between;align-items:center}
.nav h1{color:#ef4444;font-size:20px}.nav span{color:#6b7280;font-size:12px}
.container{max-width:950px;margin:24px auto;padding:0 20px}
.stats{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin-bottom:20px}
.stat{background:#111827;border:1px solid #1f2937;border-radius:10px;padding:18px;text-align:center}
.stat .val{font-size:28px;font-weight:700}.stat .lbl{font-size:11px;color:#6b7280;margin-top:4px}
.card{background:#111827;border:1px solid #1f2937;border-radius:10px;padding:20px;margin-bottom:16px}
.card h3{margin-bottom:12px;font-size:15px}
table{width:100%;border-collapse:collapse}
th{text-align:left;padding:8px;color:#6b7280;font-size:11px;border-bottom:1px solid #1f2937}
td{padding:8px;border-bottom:1px solid #1f2937;font-size:12px}
.badge{padding:2px 8px;border-radius:4px;font-size:10px;font-weight:600}
.badge-easy{background:rgba(16,185,129,0.15);color:#10b981}
.badge-medium{background:rgba(245,158,11,0.15);color:#f59e0b}
.badge-hard{background:rgba(239,68,68,0.15);color:#ef4444}
.captured{color:#10b981}.not-captured{color:#6b7280}
.cve{color:#ef4444;font-family:monospace;font-size:11px}
input[type=text]{padding:10px 14px;background:#0a0e1a;border:1px solid #2a3050;border-radius:8px;color:#e8ecf4;font-size:14px;font-family:monospace;width:300px}
button{padding:10px 20px;background:#ef4444;color:white;border:none;border-radius:8px;font-weight:600;cursor:pointer;font-size:14px}
#result{margin-top:10px;font-size:14px}
</style></head><body>
<div class="nav"><h1>AppAssault Lab</h1><span>Attacking Common Applications | {{ captured }}/{{ total }} | {{ points }}/{{ total_points }} pts</span></div>
<div class="container">
<div class="stats">
<div class="stat"><div class="val" style="color:#10b981">{{ captured }}</div><div class="lbl">Apps Compromised</div></div>
<div class="stat"><div class="val" style="color:#ef4444">{{ points }} / {{ total_points }}</div><div class="lbl">Points</div></div>
<div class="stat"><div class="val" style="color:#a78bfa">{{ pct }}%</div><div class="lbl">Completion</div></div>
</div>
<div class="card"><h3>Submit Flag</h3>
<div style="display:flex;gap:8px"><input type="text" id="flag-input" placeholder="Enter captured flag">
<button onclick="submitFlag()">Submit</button></div><div id="result"></div></div>
<div class="card"><h3>Targets</h3>
<table><thead><tr><th>#</th><th>Target</th><th>Hint</th><th>Port</th><th>Category</th><th>Points</th><th>Difficulty</th><th>Status</th></tr></thead>
<tbody>{% for f in flags %}
<tr><td>{{ f.id }}</td><td>{{ f.name }}</td>
<td><span style="color:#6b7280;font-style:italic;font-size:11px">{{ f.hint }}</span></td>
<td><span class="cve">{{ f.port }}</span></td><td>{{ f.category }}</td><td>{{ f.points }}</td>
<td><span class="badge badge-{{ f.difficulty|lower }}">{{ f.difficulty }}</span></td>
<td>{% if f.captured %}<span class="captured">PWNED</span>{% else %}<span class="not-captured">Active</span>{% endif %}</td></tr>
{% endfor %}</tbody></table></div>
</div>
<script>
async function submitFlag(){const i=document.getElementById('flag-input'),r=document.getElementById('result'),f=i.value.trim();if(!f)return;
const resp=await fetch('/api/submit',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({flag:f})});
const d=await resp.json();if(d.correct){if(d.already)r.innerHTML='<span style="color:#f59e0b">Already pwned: '+d.name+'</span>';
else{r.innerHTML='<span style="color:#10b981">PWNED! '+d.name+' +'+d.points+' pts</span>';setTimeout(()=>location.reload(),1500)}}
else r.innerHTML='<span style="color:#ef4444">Invalid flag</span>';i.value=''}
document.getElementById('flag-input').addEventListener('keydown',function(e){if(e.key==='Enter')submitFlag()});
</script></body></html>"""

@app.route("/")
def index():
    conn = sqlite3.connect(DB_PATH)
    captured_ids = [r[0] for r in conn.execute("SELECT flag_id FROM submissions WHERE captured=1").fetchall()]
    conn.close()
    flags = [dict(f, captured=f["id"] in captured_ids) for f in FLAGS]
    captured = len(captured_ids)
    points = sum(f["points"] for f in FLAGS if f["id"] in captured_ids)
    pct = int(captured * 100 / len(FLAGS)) if FLAGS else 0
    return render_template_string(HTML, flags=flags, captured=captured, total=len(FLAGS), points=points, total_points=TOTAL_POINTS, pct=pct)

@app.route("/api/submit", methods=["POST"])
def submit():
    data = request.get_json() or {}
    flag = data.get("flag", "").strip()
    if not flag:
        return jsonify({"correct": False, "message": "No flag provided"})
    flag_hash = hashlib.sha256(flag.encode()).hexdigest()
    for f in FLAGS:
        if f["hash"] == flag_hash:
            conn = sqlite3.connect(DB_PATH)
            existing = conn.execute("SELECT id FROM submissions WHERE flag_id=? AND captured=1", (f["id"],)).fetchone()
            if existing:
                conn.close()
                return jsonify({"correct": True, "already": True, "name": f["name"], "points": f["points"]})
            conn.execute("INSERT INTO submissions (flag_id, flag_name, points, submitted_at, captured) VALUES (?,?,?,?,1)",
                (f["id"], f["name"], f["points"], datetime.now().isoformat()))
            conn.commit()
            conn.close()
            return jsonify({"correct": True, "already": False, "name": f["name"], "points": f["points"]})
    return jsonify({"correct": False, "message": "Invalid flag"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
