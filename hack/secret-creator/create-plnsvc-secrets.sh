#!/bin/bash -e

main() {
    echo "Setting secrets for pipeline-service"
    create_namespace
    create_db_secret
    create_s3_secret
}

create_namespace() {
    if kubectl get namespace tekton-results &>/dev/null; then
        echo "tekton-results namespace already exists, skipping creation"
        return
    fi
    kubectl create namespace tekton-results -o yaml --dry-run=client | kubectl apply -f-
}

create_db_secret() {
    echo "Creating DB secret" >&2
    if kubectl get secret -n tekton-results tekton-results-database &>/dev/null; then
        echo "DB secret already exists, skipping creation"
        return
    fi
    kubectl create secret generic -n tekton-results tekton-results-database \
        --from-literal=db.user=tekton \
        --from-literal=db.password="$(openssl rand -base64 20)" \
        --from-literal=db.host="postgres-postgresql.tekton-results.svc.cluster.local" \
        --from-literal=db.name="tekton_results"
}

create_s3_secret() {
    echo "Creating S3 secret" >&2
    if kubectl get secret -n tekton-results tekton-results-s3 &>/dev/null; then
        echo "S3 secret already exists, skipping creation"
        return
    fi
    kubectl create secret generic -n tekton-results tekton-results-s3 \
        --from-literal=aws_access_key_id="$(cat /usr/local/ci-secrets/redhat-appstudio-load-test/aws_access_key_id)" \
        --from-literal=aws_secret_access_key="$(cat /usr/local/ci-secrets/redhat-appstudio-load-test/aws_secret_access_key)" \
        --from-literal=aws_region="$(cat /usr/local/ci-secrets/redhat-appstudio-load-test/aws_region)" \
        --from-literal=bucket="$(cat /usr/local/ci-secrets/redhat-appstudio-load-test/aws_s3_bucket)" \
        --from-literal=endpoint="$(cat /usr/local/ci-secrets/redhat-appstudio-load-test/aws_s3_endpoint)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
