#!/usr/bin/env python3

import json
import os
import subprocess
from pathlib import Path
from datetime import datetime, timezone


def run(command, timeout=12):
    environment = os.environ.copy()
    home = str(Path.home())
    environment["PATH"] = f"{home}/google-cloud-sdk/bin:{home}/.local/bin:/usr/local/bin:/usr/bin:/bin"
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=timeout, check=False, env=environment)
    except subprocess.TimeoutExpired:
        return "", "Request timed out"
    if result.returncode != 0:
        message = (result.stderr or result.stdout or "Command failed").strip().splitlines()[-1]
        return "", message
    return result.stdout, ""


def docker_rows():
    output, error = run(["docker", "ps", "--format", "{{json .}}"])
    if error:
        return [], error

    rows = []
    for line in output.splitlines():
        if not line.strip():
            continue
        container = json.loads(line)
        status_text = container.get("Status", "Unknown")
        unhealthy = "unhealthy" in status_text.lower() or "restarting" in status_text.lower()
        labels = container.get("Labels", "")
        project = "local"
        for label in labels.split(","):
            if label.startswith("com.docker.compose.project="):
                project = label.split("=", 1)[1]
                break
        rows.append({
            "id": container.get("ID", "")[:12],
            "name": container.get("Names", "Unnamed container"),
            "source": "docker",
            "scope": project,
            "status": "Unhealthy" if unhealthy else "Running",
            "detail": container.get("Image", "") + " · " + status_text,
            "problem": unhealthy,
        })
    rows.sort(key=lambda row: (not row["problem"], row["name"].lower()))
    return rows, ""


def kubernetes_rows():
    context, context_error = run(["kubectl", "config", "current-context"], timeout=4)
    context = context.strip()
    if context_error:
        return [], "", context_error

    output, error = run([
        "kubectl", "get", "deployments,statefulsets", "--all-namespaces", "-o", "json", "--request-timeout=8s"
    ], timeout=12)
    if error:
        return [], context, error

    payload = json.loads(output)
    rows = []
    now = datetime.now(timezone.utc)
    for workload in payload.get("items", []):
        metadata = workload.get("metadata", {})
        status = workload.get("status", {})
        expected = workload.get("spec", {}).get("replicas", 1)
        ready = status.get("readyReplicas", 0)
        unavailable = max(0, expected - ready)
        problem = ready < expected
        kind = workload.get("kind", "Workload")
        created = metadata.get("creationTimestamp", "")
        age = ""
        if created:
            try:
                seconds = max(0, int((now - datetime.fromisoformat(created.replace("Z", "+00:00"))).total_seconds()))
                age = f"{seconds // 86400}d" if seconds >= 86400 else f"{seconds // 3600}h" if seconds >= 3600 else f"{seconds // 60}m"
            except ValueError:
                pass
        rows.append({
            "id": f"{ready}/{expected}",
            "name": metadata.get("name", "Unnamed workload"),
            "source": "kubernetes",
            "scope": metadata.get("namespace", "default"),
            "status": "Unavailable" if problem else "Healthy",
            "detail": f"{kind} · {unavailable} unavailable" + (f" · age {age}" if age else ""),
            "problem": problem,
        })
    rows.sort(key=lambda row: (not row["problem"], row["scope"], row["name"]))
    return rows, context, ""


def main():
    docker, docker_error = docker_rows()
    kubernetes, context, kubernetes_error = kubernetes_rows()
    rows = docker + kubernetes
    if docker_error:
        rows.append({
            "id": "ERR",
            "name": "Docker unavailable",
            "source": "docker",
            "scope": "local",
            "status": "Unavailable",
            "detail": docker_error,
            "problem": True,
        })
    if kubernetes_error:
        rows.append({
            "id": "ERR",
            "name": "Kubernetes unavailable",
            "source": "kubernetes",
            "scope": context or "current context",
            "status": "Unavailable",
            "detail": kubernetes_error,
            "problem": True,
        })
    print(json.dumps({
        "rows": rows,
        "context": context,
        "dockerError": docker_error,
        "kubernetesError": kubernetes_error,
        "problemCount": sum(1 for row in rows if row["problem"]),
    }))


if __name__ == "__main__":
    main()
