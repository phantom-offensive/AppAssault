FROM jenkins/jenkins:2.441

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Set up via Groovy init scripts
COPY init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/

# Entrypoint: inject flag and template jenkins.yaml at runtime
USER root
COPY jenkins.yaml.template /usr/share/jenkins/ref/jenkins.yaml.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Breadcrumb: internal deployment notes
RUN mkdir -p /opt/widget-corp && \
    printf '# Widget Corp CI/CD Pipeline Notes\n# Last updated: 2026-03-15\n\n## GitLab Integration\nGitLab URL: http://gitlab.widgetcorp.local:9006\n\n## Deployment Pipeline\n- Jenkins pulls from GitLab repos\n- Builds are deployed to Tomcat app server\n- Monitoring via Splunk dashboard\n\n## TODO\n- Rotate GitLab root password\n- Set up SSO between Jenkins and GitLab\n' > /opt/widget-corp/pipeline-notes.txt && \
    chmod 644 /opt/widget-corp/pipeline-notes.txt

USER jenkins
ENTRYPOINT ["/entrypoint.sh"]
