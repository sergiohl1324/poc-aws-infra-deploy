# poc-aws-infra-deploy

POC de infraestructura AWS para entrevista de trabajo: **VPC + ALB + Application Server (nginx, con bonus uWSGI)**.

Orquesta 3 módulos Terraform propios:
- [mod-aws-vpc](https://github.com/sergiohl1324/mod-aws-vpc)
- [mod-aws-alb](https://github.com/sergiohl1324/mod-aws-alb)
- [mod-aws-app-server](https://github.com/sergiohl1324/mod-aws-app-server) (a su vez usa [mod-aws-iam-role](https://github.com/sergiohl1324/mod-aws-iam-role))

## Arquitectura

- 1 VPC, sin NAT Gateway (ahorro de costo) — el Application Server vive en subnet **pública** con IP pública propia para salida a internet (apt/pip/SSM).
- 1 ALB (HTTP:80) → 1 Target Group → la instancia EC2.
- El Security Group del EC2 solo permite ingress :80 **desde el SG del ALB** — sin SSH abierto. Acceso administrativo vía **SSM Session Manager**.
- Bonus uWSGI controlado por la variable `enable_uwsgi`: en `false` nginx sirve el HTML estático; en `true` nginx hace reverse proxy a uWSGI.

## Uso

```bash
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars: completar ami_id con un AMI Ubuntu 22.04/24.04 LTS vigente en la región

terraform init
terraform plan
terraform apply
```

Probar:

```bash
curl http://$(terraform output -raw alb_dns_name)
```

Debe responder el HTML con "Served via: nginx static".

### Activar el bonus uWSGI

```bash
# en terraform.tfvars: enable_uwsgi = true
terraform apply
```

El plan mostrará `# forces replacement` en la instancia EC2 (cambia el `user_data`, a propósito no se ignora ese cambio — ver README de `mod-aws-app-server`). Esperar boot (~2-3 min, compila uWSGI) y volver a `curl` — ahora debe responder "Served via: nginx + uWSGI".

### Debug

Sin SSH abierto:

```bash
aws ssm start-session --target $(terraform output -raw app_server_instance_id)
cat /var/log/user-data.log
journalctl -u uwsgi
```

### Al terminar — destruir

```bash
terraform destroy
```

**Importante:** el ALB tiene costo fijo por hora (~$0.0225/h + LCU) y la EC2 también — no dejar la infra corriendo después de la entrevista.

## Notas de implementación

- **Backend de state: local** (sin bloque `backend` explícito). No se justifica bootstrap de S3+DynamoDB para una POC de un solo uso — mejora futura si se quisiera reutilizar este setup.
- Los módulos se referencian con `?ref=main` (no hay tags `v0.1.0` creados todavía porque la herramienta usada para automatizar esto no tenía permiso para crear git tags vía API). Para fijar versión real: en cada repo de módulo ejecutar `git fetch && git tag v0.1.0 && git push --tags`, y luego cambiar `?ref=main` por `?ref=v0.1.0` en `main.tf`.
- `mod-aws-security-group` (repo histórico) no se usa aquí — el Security Group del ALB se crea como recurso nativo `aws_security_group` directamente en este repo, para no depender de un módulo adicional que sigue siendo privado.
