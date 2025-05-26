Automated Execution via CI/CD (Optional)
Some teams wire this into a CI pipeline, for example:

GitHub Actions

GitLab CI/CD

Jenkins


Example: GitHub Actions

- name: Bootstrap Argo CD
  run: |
    cd kubernetes/bootstrap
    ./init.sh