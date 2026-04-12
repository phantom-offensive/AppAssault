#!/bin/bash
# Inject flag and credentials at runtime (not baked into image)
echo "$FLAG_JENKINS" > /flag.txt
chmod 644 /flag.txt

# Template jenkins.yaml with env vars
sed -e "s|\${FLAG_JENKINS}|${FLAG_JENKINS}|g" \
    -e "s|\${JENKINS_DEPLOY_PASSWORD}|${JENKINS_DEPLOY_PASSWORD}|g" \
    -e "s|\${GITLAB_ROOT_PASSWORD}|${GITLAB_ROOT_PASSWORD}|g" \
    /usr/share/jenkins/ref/jenkins.yaml.template > /usr/share/jenkins/ref/jenkins.yaml

# Update pipeline notes breadcrumb with actual GitLab password
if [ -n "$GITLAB_ROOT_PASSWORD" ]; then
    printf '# Widget Corp CI/CD Pipeline Notes\n# Last updated: 2026-03-15\n\n## GitLab Integration\nGitLab URL: http://gitlab.widgetcorp.local:9006\nAdmin user: root\nAdmin pass: %s\n\n## Deployment Pipeline\n- Jenkins pulls from GitLab repos\n- Builds are deployed to Tomcat app server\n- Monitoring via Splunk dashboard\n\n## TODO\n- Rotate GitLab root password (been meaning to do this for months)\n- Set up SSO between Jenkins and GitLab\n' "$GITLAB_ROOT_PASSWORD" > /opt/widget-corp/pipeline-notes.txt
fi

exec /usr/local/bin/jenkins.sh "$@"
