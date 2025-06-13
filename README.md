# Les 06

## Opdracht
Maak een complete deployment waarin je een Azure VM en ESXi VM combineert en je een hybrid cloud situatie maakt. Gebruik de stof van de afgelopen lessen. De deployment is compleet geautomatiseerd, inclusief het aanmaken van VM’s en andere resources in Azure.
Maak op beide omgeving een gebruiker ‘testuser’ aan, via Ansible of via Terraform. De testuser kan inloggen van de ESXI VM naar de Azure VM, het plaatsen van de benodigde SSH keys is geautomatiseerd.
Op beide systemen draait Docker (wat je geïnstalleerd hebt via een zelfgemaakte ansible-galaxy role) en via CI/CD gebouwde “Hello World” Docker container.

## Requirements voor het uitvoeren van de code:
- Terraform
- Ansible 
- Lokaal geinstalleerd Github runner
- Ansible Galaxy role: `BurenRaas.docker`


### Handmatig uitvoeren van de code


**Terraform:**
```bash
terraform init
terraform apply --auto-approve
```

**Ansible:**

```bash
ansible-galaxy install BurenRaas.docker
ansible-playbook -i inventory.ini playbooks/testuser_playbook.yml
ansible-playbook -i inventory.ini playbooks/docker-role_playbook.yml
```


## Terraform code

- `main.tf`: definieert de virtuele machines op ESXi en Azure. De resource `null_resource.generate_inventory_and_known_hosts` genereert automatisch een `inventory.ini` bestand voor Ansible en voegt de IP-adressen van de VM’s toe aan de SSH known_hosts, zodat Ansible verbinding kan maken.
- `variables.tf`: bevat variabelen voor de verbinding met de ESXi host.
- `cloud-config.yml`:   configuratie voor het aanmaken van gebruiker `student` met SSH toegang, zodat zowel de beheerder (ik) en Ansible altijd toegang hebben tot de VM.


## Ansible code

**Playbook: `testuser_playbook.yml`**  
Dit playbook maakt de gebruiker `testuser` aan op beide VM’s en kopieert automatisch de juiste SSH keys. Daarnaast krijgt deze gebruiker sudo-rechten, zodat hij `docker run` kan uitvoeren (handig voor de demo).

**Playbook: `docker-role_playbook.yml`**  
Installeert de Ansible Galaxy role `BurenRaas.docker` en voert deze uit. Docker wordt daarmee geïnstalleerd en de container `hello-world` wordt opgehaald.  
Deze container moet handmatig worden gestart, omdat hij zichzelf beëindigt na één keer draaien.


## GIT actions worklfow 

De CI/CD-pipeline om de omgeving op te bouwen is bedacht met in gedachte: eerste controleren en dan pas uitvoeren:

1. **Codecontrole**  
   - Terraform code wordt gecontrolleerd met: `terraform validate`, `terraform fmt`.
   - Ansible code wordt gecontrolleerd met: `ansible-lint`.

2. **Uitrol**  
   - Terraform deployt de infrastructuur.
   - Ansible maakt `testuser` aan, kopieert SSH keys, installeert Docker en haalt de container `hello-world` op.

De pipeline wordt automatisch geactiveerd bij een **push naar de `main` en `test` branch**, via het workflowbestand `cicd_apply.yml`.

De infrastructuur kan handmatig verwijderd worden door het uitvoeren van de pipeline `cicd_destroy.yml`. Deze workflow is beschikbaar in de `.github/workflows` map en activeer je handmatig via de **workflow_dispatch** optie in GitHub. In de workflow wordt Terraform destroy uitgevoerd om de omgeving te verwijderen.

## Bronnen

- Code gebruikt uit:
  - Les 5 opdracht 2 en 3
  - Les 2 opdracht 2B

- Ansible Docker role AI Prompt:  
  https://chatgpt.com/share/684a9121-a41c-8007-a64c-1f4442b87990

- Ansible inventory fix AI Prompt:  
  https://chatgpt.com/share/684a9121-a41c-8007-a64c-1f4442b87990

Ruben Baas
s1190828
