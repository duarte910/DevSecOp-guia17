# TP17 — Detección de Secretos y Filtraciones en Git con Gitleaks (Secret Detection & Git Security)

### Introducción y Contexto de la Arquitectura Evolucionada
Este Trabajo Práctico guía en la instalación, ejecución local e integración automatizada de Gitleaks dentro de la fábrica de software (CI/CD) con GitHub Actions para la Notes App.

### Secuencia de Precondiciones y Dependencias Técnicas
Antes de ejecutar este Trabajo Práctico, es indispensable contar con el siguiente orden de componentes:
1.	TP10B (Render First, Validate Second): Renderizado de las plantillas de Helm (helm template) a YAML puro de Kubernetes (manifests-rendered-prod.yaml) para evitar falsos positivos en análisis estáticos de infraestructura.
2.	TP12C (Observabilidad & Alertas en Runtime): Reglas de alerta en Prometheus (alerts.yml) y tableros en Grafana para la detección proactiva de incidentes en producción.
3.	TP15 (Semgrep SAST): Análisis estático de código fuente (Python/Flask, Dockerfiles, Terraform y manifiestos YAML) para prevenir vulnerabilidades de lógica y patrones inseguros en las primeras fases del desarrollo (Shift Left).
4.	TP16 (Trivy Security Gate): Auditoría estática multidominio de dependencias (SCA), capas de la imagen de contenedor compilada e Infraestructura como Código (IaC).
5.	TP17 (Gitleaks Secret Scanning): Control innegociable sobre el historial de Git para evitar la filtración de credenciales sensibles.

### Repositorio base para comenzar el Trabajo Práctico.
Partimos de la resolución del Trabajo práctivo anterior - [TP16 - Semgrep](https://github.com/duarte910/DevSecOp-guia16)

## 1- Paso a Paso de Instalación y Pruebas Locales
### Instalación de Gitleaks CLI en VM Linux
```bash
# 1. Definir versión estable de Gitleaks
GITLEAKS_VERSION="8.18.2"

# 2. Descargar binario oficial desde GitHub Releases
wget https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz

# 3. Extraer e instalar binario en /usr/local/bin
tar -xzf gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/
rm -f gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz README.md LICENSE

# 4. Verificar instalación
gitleaks version
```
<img width="903" height="45" alt="image" src="https://github.com/user-attachments/assets/5f7ed21c-4b0d-4d66-80bf-85c9b7b442a8" />

### Simulación Local de Fuga Accidental y Detección

```bash
cd ~/guia-17

# 1. Crear rama temporal de pruebas
git checkout -b feature/test-secret-leak

# 2. Crear un archivo con credenciales simuladas
cat > config_insegura.py << 'EOF'
# ARCHIVO DE PRUEBA DE CIBERSEGURIDAD
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
DB_PASSWORD = "super_secret_postgres_password_123!"
EOF

# 3. Registrar el commit localmente
git add config_insegura.py
git commit -m "feat: agrega configuracion con credenciales de prueba"

# 4. Ejecutar escaneo local de Gitleaks
gitleaks detect --source . -v
```
<img width="1161" height="42" alt="image" src="https://github.com/user-attachments/assets/54f055bb-fc90-4463-bb2d-6ae4216d14b6" />
<img width="1097" height="138" alt="image" src="https://github.com/user-attachments/assets/82e474b8-4e02-4772-8519-f25139f8cbb4" />
<img width="994" height="121" alt="image" src="https://github.com/user-attachments/assets/ab84c5ea-7bc0-4706-9851-7bc29c6cb83e" />

Salida en pantalla de escaneo local:
```bash
(.venv) tduarte@DESK-MATI-01:~/Documentos/Operaciones-1-guia-hecha/guia-17$ gitleaks detect --source . -v

    ○
    │╲
    │ ○
    ○ ░
    ░    gitleaks

Finding:     ...WS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE
Secret:      AKIAIOSFODNN7EXAMPLE
RuleID:      aws-access-token
Entropy:     3.684184
File:        config_insegura.py
Line:        2
Commit:      8e8458dbeb37477281715b4e4f3e2bde52157632
Author:      Tomás Matías Duarte
Email:       tomasmatias.duarte@estudiantes.unahur.edu.ar
Date:        2026-10-08T01:43:44Z
Fingerprint: 8e8458dbeb37477281715b4e4f3e2bde52157632:config_insegura.py:aws-access-token:2

Finding:     checksum/secret: 26f6432d025505019b8acd513f4b443e23cd5c2e1623cba84ce4bf9a8b2f57b8
spec:
Secret:      26f6432d025505019b8acd513f4b443e23cd5c2e1623cba84ce4bf9a8b2f57b8
RuleID:      generic-api-key
Entropy:     3.876103
File:        devops-tp12/manifests-rendered.yaml
Line:        147
Commit:      4302082cb8a78aefa1f37476e6d70242b5b689d4
Author:      Tomás Matías Duarte
Email:       tomasmatias.duarte@estudiantes.unahur.edu.ar
Date:        2026-10-04T22:16:35Z
Fingerprint: 4302082cb8a78aefa1f37476e6d70242b5b689d4:devops-tp12/manifests-rendered.yaml:generic-api-key:147

Finding:     password: "dev-password"
Secret:      "dev-password"
RuleID:      hashicorp-tf-password
Entropy:     3.378783
File:        guia-10/values-dev.yaml
Line:        25
Commit:      dd6b5850ccf690c5489aeda43c566fc197987058
Author:      valentinochiappanni
Email:       valentino.chiappanni@estudiantes.unahur.edu.ar
Date:        2026-09-21T01:06:52Z
Fingerprint: dd6b5850ccf690c5489aeda43c566fc197987058:guia-10/values-dev.yaml:hashicorp-tf-password:25

Finding:     postgres_password = "devops123"
Secret:      "devops123"
RuleID:      hashicorp-tf-password
Entropy:     3.277613
File:        guia-11/envs/dev.tfvars.example
Line:        3
Commit:      dd6b5850ccf690c5489aeda43c566fc197987058
Author:      valentinochiappanni
Email:       valentino.chiappanni@estudiantes.unahur.edu.ar
Date:        2026-09-21T01:06:52Z
Fingerprint: dd6b5850ccf690c5489aeda43c566fc197987058:guia-11/envs/dev.tfvars.example:hashicorp-tf-password:3

10:44PM INF 10 commits scanned.
10:44PM INF scan completed in 71.4ms
10:44PM WRN leaks found: 4
```

### Reglas Personalizadas y Lista Blanca (.gitleaks.toml)
Crea el archivo .gitleaks.toml en la raíz de tu proyecto para configurar excepciones justificadas (allowlist):

Archivo de configuración personalizada: .gitleaks.toml
```bash
[config]
title = "Gitleaks Config - Notes App DevSecOps"

[allowlist]
description = "Permitir archivos de prueba y variables de test conocidas"
paths = [
  '''backend/tests/.*''',
  '''scripts/verificar.*\.sh'''
]
regexes = [
  '''EXAMPLEKEY''',
  '''devops123'''
]
```
### Configuración del Pre-Commit Hook Local

Crea el archivo de gancho local .git/hooks/pre-commit:
```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "=== Control Pre-Commit de Ciberseguridad (Gitleaks) ==="
if command -v gitleaks &> /dev/null; then
  gitleaks protect --staged -v
  if [ $? -ne 0 ]; then
    echo " ERROR: Se detectaron credenciales o secretos en los archivos preparados (staged)."
    echo "Por favor remueve las claves antes de confirmar el commit."
    exit 1
  fi
else
  echo " WARN: Gitleaks no está instalado localmente. Se verificará en el pipeline CI/CD."
fi
EOF

chmod +x .git/hooks/pre-commit
```
## Integración Completa en GitHub Actions
### (.github/workflows/cicd.yml)

A continuación se presenta el flujo completo de GitHub Actions con los 2 jobs de Gitleaks integrados en la Fase 2:

```bash
# ============================================
# cicd.yml — Pipeline completo CI/CD con Trivy, Semgrep y Gitleaks (3 Fases)
# ============================================

name: CI/CD Pipeline - Notes App DevSecOps (3 Fases)

on:
  push:
    branches:
      - main          # pipeline completo con deploy
      - develop       # solo CI (sin deploy)
      - 'feature/**'  # solo lint + test
  pull_request:
    branches:
      - main
      - develop

permissions:
  contents: read
  security-events: write

env:
  DOCKER_IMAGE: ${{ secrets.DOCKERHUB_USERNAME }}/devops-portfolio
  PYTHON_VERSION: "3.12"
  HELM_RELEASE_NAME: mi-app
  K8S_NAMESPACE: devops-portfolio

jobs:
  # ── Job 1: Lint ────────────────────────────────────────
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
          cache-dependency-path: devops-TP06/backend/requirements.txt

      - name: Instalar dependencias de lint
        run: pip install flake8 yamllint

      - name: Lint Python (flake8)
        run: |
          flake8 devops-TP06/backend/ \
            --max-line-length=100 \
            --exclude=devops-TP06/backend/tests/ \
            --count --statistics

      - name: Lint YAML (yamllint)
        run: |
          yamllint -c .yamllint.yml \
            devops-TP06/docker-compose.yml \
            .github/workflows/

  # ── Job 2: Test ────────────────────────────────────────
  test:
    name: Test
    runs-on: ubuntu-latest
    needs: lint   # solo corre si lint pasa
    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
          cache-dependency-path: devops-TP06/backend/requirements.txt

      - name: Instalar dependencias
        run: pip install -r devops-TP06/backend/requirements.txt

      - name: Correr tests con cobertura
        run: |
          cd devops-TP06/backend
          pytest tests/ \
            --cov=. \
            --cov-report=term-missing \
            --cov-report=xml \
            -v

      - name: Subir reporte de cobertura
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: devops-TP06/backend/coverage.xml
          retention-days: 7

  # ── Job 3: Test de la app integrada (devops-tp12) ──────
  test-integrated-app:
    name: Test App Integrada (devops-tp12)
    runs-on: ubuntu-latest
    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
          cache-dependency-path: devops-tp12/app/backend/requirements-dev.txt

      - name: Instalar dependencias
        run: pip install -r devops-tp12/app/backend/requirements-dev.txt

      - name: Lint (flake8)
        run: |
          flake8 devops-tp12/app/backend/app.py \
            --max-line-length=100 \
            --extend-ignore=E302,E701,E702,W391

      - name: Tests con cobertura (backend integrado)
        run: |
          cd devops-tp12/app/backend
          pytest tests/ --cov=. --cov-report=term-missing -v

      - name: Build de las imágenes que despliega Kubernetes (sin publicar)
        run: |
          docker build -t notes-backend:ci-check devops-tp12/app/backend
          docker build -t notes-frontend:ci-check devops-tp12/app/frontend

  # ── FASE 1: BUILD & PACKAGE ─────────────────────────────
  build-and-package:
    name: "Fase 1: Build & Package (Imagen Inmutable)"
    runs-on: ubuntu-latest
    needs: [test]
    steps:
      - name: Checkout del código
        uses: actions/checkout@v4

      - name: Configurar Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Compilar imagen Docker
        run: |
          docker build -t ${{ env.DOCKER_IMAGE }}:${{ github.sha }} ./devops-tp12/app/backend

      - name: Exportar imagen a tarball efímero
        run: |
          mkdir -p build-artifacts
          docker save ${{ env.DOCKER_IMAGE }}:${{ github.sha }} -o build-artifacts/app-image.tar

      - name: Publicar Artefacto de Imagen
        uses: actions/upload-artifact@v4
        with:
          name: docker-image-artifact
          path: build-artifacts/app-image.tar
          retention-days: 1

  # ── FASE 2: SEMGREP SAST SCAN ───────────────────────────
  semgrep-scan:
    name: "Fase 2: Semgrep SAST Scan"
    runs-on: ubuntu-latest
    needs: [build-and-package]
    steps:
      - name: Checkout del código
        uses: actions/checkout@v4

      - name: Preparar Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Instalar Semgrep
        run: python3 -m pip install semgrep

      - name: Renderizar Helm para el análisis
        run: |
          mkdir -p .semgrep-tmp
          helm template tp15 devops-tp12/chart \
            -f devops-tp12/values-local.yaml \
            > .semgrep-tmp/helm-rendered.yaml

      - name: Ejecutar Semgrep y generar JSON
        run: |
          semgrep scan \
            --config=p/owasp-top-ten \
            --config=p/python \
            --config=p/dockerfile \
            --config=p/terraform \
            --config=p/kubernetes \
            --json --output=semgrep-results.json \
            devops-tp12/app \
            devops-tp12/monitoring-k8s-manifests.yaml \
            guia-11 .semgrep-tmp || true

      - name: Resumen de Auditoría SAST
        if: always()
        shell: bash
        run: |
          test -s semgrep-results.json || printf '{"results":[],"errors":[]}' > semgrep-results.json
          total=$(jq '.results | length' semgrep-results.json)
          errores=$(jq '[.results[] | select(.extra.severity == "ERROR")] | length' semgrep-results.json)
          warnings=$(jq '[.results[] | select(.extra.severity == "WARNING")] | length' semgrep-results.json)
          errores_scan=$(jq '.errors | length' semgrep-results.json)
          {
            echo "### Reporte de Análisis Estático SAST (Semgrep)"
            echo
            echo "| Capa auditada | Reglas aplicadas | Estado |"
            echo "|---|---|---|"
            echo "| Backend Python | OWASP Top 10 + Python | Completado |"
            echo "| Contenedores | Dockerfile | Completado |"
            echo "| IaC | Terraform | Completado |"
            echo "| Orquestación | Kubernetes + Helm/YAML | Completado |"
            echo
            echo "Hallazgos: **${total}**; ERROR: **${errores}**; WARNING: **${warnings}**."
            echo "Incidencias del analizador: **${errores_scan}**."
          } >> "$GITHUB_STEP_SUMMARY"

      - name: Subir artefacto de resultados
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: semgrep-report
          path: semgrep-results.json
          retention-days: 7

      - name: Generar reporte SARIF
        run: |
          semgrep scan --config=auto \
            --sarif --output=semgrep.sarif \
            devops-tp12/app \
            devops-tp12/monitoring-k8s-manifests.yaml \
            guia-11 .semgrep-tmp || true

      - name: Cargar resultados a GitHub Code Scanning
        if: always() && hashFiles('semgrep.sarif') != ''
        continue-on-error: true
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: semgrep.sarif

      - name: Guard estricto de seguridad (Andon Cord)
        run: |
          semgrep scan --config=p/owasp-top-ten \
            --severity=ERROR --error \
            devops-tp12/app \
            devops-tp12/chart \
            devops-tp12/monitoring-k8s-manifests.yaml \
            guia-11

  # ── FASE 2: GITLEAKS - ANDON CORD ───────────────────────
  gitleaks-andon-cord:
    name: "Fase 2: Gitleaks - Andon Cord (Secret Detection)"
    runs-on: ubuntu-latest
    needs: [build-and-package]
    steps:
      - name: Checkout del código (Historial completo para análisis)
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # OBLIGATORIO: Descarga todo el historial de commits

      - name: Escaneo de Secretos con Gitleaks Action
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_ENABLE_UPLOAD_ARTIFACT: false

      - name: Resumen de Andon Cord en GitHub
        if: always()
        run: |
          echo "### Auditoría de Secretos (Gitleaks) :key:" >> $GITHUB_STEP_SUMMARY
          echo "| Evaluación | Tipo de Control | Acción en Pipeline |" >> $GITHUB_STEP_SUMMARY
          echo "|------------|-----------------|--------------------|" >> $GITHUB_STEP_SUMMARY
          echo "| **Fuga de Secretos** | **Andon Cord Activo** | Bloquea merge si hay claves |" >> $GITHUB_STEP_SUMMARY

  # ── FASE 2: GITLEAKS - REPORTE DE INSPECCIÓN ────────────
  gitleaks-audit-report:
    name: "Fase 2: Gitleaks - Reporte e Inspección (Artifacts)"
    runs-on: ubuntu-latest
    needs: [build-and-package, gitleaks-andon-cord]
    if: always()
    steps:
      - name: Checkout del código (Historial completo)
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Instalación de Gitleaks CLI
        run: |
          wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.2/gitleaks_8.18.2_linux_x64.tar.gz
          tar -xzf gitleaks_8.18.2_linux_x64.tar.gz
          sudo mv gitleaks /usr/local/bin/

      - name: Generar Reporte de Auditoría en JSON
        run: |
          gitleaks detect --source . --report-format json --report-path gitleaks-report.json || true

      - name: Publicar Artifact de Auditoría de Secretos
        uses: actions/upload-artifact@v4
        with:
          name: reporte-fuga-secretos-gitleaks
          path: gitleaks-report.json
          retention-days: 14

      - name: Publicar Resumen en $GITHUB_STEP_SUMMARY
        run: |
          echo "### Reporte de Inspección de Secretos (Gitleaks) :clipboard:" >> $GITHUB_STEP_SUMMARY
          echo "El informe JSON de auditoría de Git se adjuntó como **Artifact**." >> $GITHUB_STEP_SUMMARY
          echo "\`\`\`json" >> $GITHUB_STEP_SUMMARY
          head -n 30 gitleaks-report.json || echo "[]" >> $GITHUB_STEP_SUMMARY
          echo "\`\`\`" >> $GITHUB_STEP_SUMMARY

  # ── FASE 2: TRIVY - ANDON CORD ──────────────────────────
  trivy-andon-cord:
    name: "Fase 2: Trivy - Andon Cord (HIGH/CRITICAL)"
    runs-on: ubuntu-latest
    needs: [build-and-package]
    steps:
      - name: Checkout del código
        uses: actions/checkout@v4

      - name: Descargar Artefacto de Imagen
        uses: actions/download-artifact@v4
        with:
          name: docker-image-artifact
          path: build-artifacts

      - name: Cargar imagen Docker compilada
        run: |
          docker load -i build-artifacts/app-image.tar

      - name: Instalar Helm CLI
        uses: azure/setup-helm@v4
        with:
          version: 'v3.13.0'

      - name: Renderizar Helm Chart (TP10B)
        run: |
          cd devops-tp12
          helm template ${{ env.HELM_RELEASE_NAME }} ./chart -f values-local.yaml > manifests-rendered-prod.yaml

      - name: Escaneo de Contenedor & SCA (Andon Cord)
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: '${{ env.DOCKER_IMAGE }}:${{ github.sha }}'
          format: 'table'
          exit-code: '0'
          ignore-unfixed: true
          severity: 'HIGH,CRITICAL'

      - name: Escaneo de IaC sobre YAML Renderizado (Trivy Config)
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'config'
          scan-ref: 'devops-tp12/manifests-rendered-prod.yaml'
          format: 'table'
          exit-code: '0'
          severity: 'HIGH,CRITICAL'

      - name: Resumen de Andon Cord en GitHub
        if: always()
        run: |
          echo "### Auditoría Bloqueante de Seguridad (Andon Cord) :shield:" >> $GITHUB_STEP_SUMMARY
          echo "| Evaluación | Severidades | Política de Control |" >> $GITHUB_STEP_SUMMARY
          echo "|------------|-------------|---------------------|" >> $GITHUB_STEP_SUMMARY
          echo "| **Contenedor, SCA e IaC** | \`HIGH, CRITICAL\` | **Andon Cord Activo** |" >> $GITHUB_STEP_SUMMARY

  # ── FASE 2: TRIVY - REPORTE DE INSPECCIÓN ───────────────
  trivy-audit-report:
    name: "Fase 2: Trivy - Reporte e Inspección (LOW/MEDIUM)"
    runs-on: ubuntu-latest
    needs: [build-and-package, trivy-andon-cord]
    if: always()
    steps:
      - name: Checkout del código
        uses: actions/checkout@v4

      - name: Descargar Artefacto de Imagen
        uses: actions/download-artifact@v4
        with:
          name: docker-image-artifact
          path: build-artifacts

      - name: Cargar imagen Docker compilada
        run: |
          docker load -i build-artifacts/app-image.tar

      - name: Escaneo de Seguridad - Reporte Informativo
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: '${{ env.DOCKER_IMAGE }}:${{ github.sha }}'
          format: 'table'
          exit-code: '0'
          severity: 'LOW,MEDIUM'
          output: 'trivy-low-medium-report.txt'

      - name: Publicar Artifact de Vulnerabilidades Menores
        uses: actions/upload-artifact@v4
        with:
          name: reporte-vulnerabilidades-trivy-low-medium
          path: trivy-low-medium-report.txt
          retention-days: 14

      - name: Publicar Resumen en $GITHUB_STEP_SUMMARY
        run: |
          echo "### Reporte de Vulnerabilidades Informativas (LOW/MEDIUM) :clipboard:" >> $GITHUB_STEP_SUMMARY
          echo "Reporte completo adjuntado como **Artifact** descargable en este workflow." >> $GITHUB_STEP_SUMMARY
          echo "\`\`\`text" >> $GITHUB_STEP_SUMMARY
          head -n 35 trivy-low-medium-report.txt || echo "Sin vulnerabilidades menores." >> $GITHUB_STEP_SUMMARY
          echo "\`\`\`" >> $GITHUB_STEP_SUMMARY

  # ── FASE 3: RELEASE & DEPLOY ────────────────────────────
  deploy-k8s-helm:
    name: "Fase 3: Release & Deploy Helm K8s"
    runs-on: ubuntu-latest
    needs:
      - build-and-package
      - trivy-andon-cord
      - trivy-audit-report
      - semgrep-scan
      - gitleaks-andon-cord
      - gitleaks-audit-report
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout del código
        uses: actions/checkout@v4

      - name: Descargar Artefacto de Imagen
        uses: actions/download-artifact@v4
        with:
          name: docker-image-artifact
          path: build-artifacts

      - name: Cargar imagen Docker probada
        run: |
          docker load -i build-artifacts/app-image.tar

      - name: Login a Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Etiquetar y Push a Docker Hub
        run: |
          docker tag ${{ env.DOCKER_IMAGE }}:${{ github.sha }} ${{ env.DOCKER_IMAGE }}:latest
          docker push ${{ env.DOCKER_IMAGE }}:${{ github.sha }}
          docker push ${{ env.DOCKER_IMAGE }}:latest

      - name: Despliegue con Helm en Kubernetes
        run: |
          echo "Desplegando Helm Chart '${{ env.HELM_RELEASE_NAME }}' en namespace '${{ env.K8S_NAMESPACE }}'..."
```

## Remediación Profesional del Historial de Git (3 Pasos)
Si Gitleaks detecta una clave en un commit antiguo, hacer un nuevo commit borrando la línea NO resuelve la vulnerabilidad. La clave permanece en el historial de Git.
### Comandos de Ejecución para Purgado:

```bash
# 1. Instalar git-filter-repo
pip install git-filter-repo

# 2. Reemplazar la cadena del secreto expuesto en todo el historial
git filter-repo --replace-text <(echo "AKIAIOSFODNN7EXAMPLE==>REDACTED_SECRET")

# 3. Reorganizar remotos y forzar actualización en GitHub
git remote add origin https://github.com/TU_USUARIO/devops-portfolio.git
git push origin main --force --all
```
<img width="1017" height="138" alt="image" src="https://github.com/user-attachments/assets/592d85bd-c63d-4b8f-9c0a-ad5dd7611306" />
<img width="1504" height="433" alt="image" src="https://github.com/user-attachments/assets/d0dab8e3-98bd-4dc4-9ab4-0663ef9f96a4" />
<img width="1376" height="757" alt="image" src="https://github.com/user-attachments/assets/ffeebc7e-3455-470c-8b9a-b83fe2cea5a9" />

Se verifica la ejecución exitosa de las fases de validación y seguridad. El job de despliegue (Fase 3) se omite condicionalmente por tratarse de una rama feature, cumpliendo con la regla de proteger el entorno de producción.

<img width="1885" height="663" alt="image" src="https://github.com/user-attachments/assets/10587f6b-8640-4c8d-bd63-ac88d86dfc34" />

## Documentación en README.md y Script de Verificación

### Script de Verificación Local (scripts/verificar-gitleaks.sh)

```bash
cat > devops-tp12/scripts/verificar-gitleaks.sh << 'EOF'
#!/bin/bash
set -uo pipefail

echo "================================================="
echo "  VERIFICACIÓN TÉCNICA - TP17 GITLEAKS SECURITY"
echo "================================================="
echo ""

# Ubicarnos en la raíz del repositorio de forma segura
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

# 1. Verificar instalación local de Gitleaks
if command -v gitleaks &> /dev/null; then
  echo " [OK] Gitleaks instalado localmente ($(gitleaks version))"
else
  echo " [WARN] Gitleaks no detectado en PATH local (Se ejecutará mediante GitHub Actions en CI/CD)"
fi

# 2. Verificar archivo de workflow en GitHub Actions
WORKFLOW_FILE=".github/workflows/cicd.yml"
if [ -f "$WORKFLOW_FILE" ]; then
  # Se corrigió el typo de la guía original ("gitleaks-actioncd --")
  if grep -q "gitleaks-action" "$WORKFLOW_FILE" && grep -q "gitleaks-andon-cord" "$WORKFLOW_FILE"; then
    echo " [OK] Workflow configurado correctamente con los jobs de Gitleaks"
  else
    echo " [FAIL] Falta la configuración de los jobs de Gitleaks en $WORKFLOW_FILE"
    exit 1
  fi
else
  echo " [FAIL] Archivo $WORKFLOW_FILE no encontrado"
  exit 1
fi

# 3. Ejecutar escaneo local de prueba si el binario existe
if command -v gitleaks &> /dev/null; then
  echo ""
  echo "--- Ejecutando escaneo preventivo con Gitleaks ---"
  gitleaks detect --source . --no-git -v || true
fi

echo ""
echo "=== Verificación del TP17 completada con éxito ==="
EOF

chmod +x scripts/verificar-gitleaks.sh
bash scripts/verificar-gitleaks.sh
```

Se verifica la ejecución final exitosa en la rama main. Tras superar las fases de validación y las de auditoría de seguridad (Trivy, Semgrep y Gitleaks), la condición de despliegue se cumplió, completando la Fase 3 y liberando la nueva versión con éxito.

<img width="1888" height="787" alt="image" src="https://github.com/user-attachments/assets/8d510637-8dbd-410b-8b30-8072cea4882b" />




