# tf-experiments

## To test this out
1. Open this repo in GitHub Codespaces
1. Follow steps under 'Notes'

## Notes
1. Run
    ```sh
    az ad sp create-for-rbac --role=Contributor --scopes=/subscriptions/<subId>
    ```

2. Create a file under `.devcontainer/devcontainer.env` with the following (replacing `<val>` with output from previous step):
    ```
    ARM_CLIENT_ID=<val>
    ARM_SUBSCRIPTION_ID=<val>
    ARM_TENANT_ID=<val>
    ARM_CLIENT_SECRET=<val>
    ```

3. In `infra` folder:
    ```sh
    terraform init
    terraform plan
    terraform apply
    ```

4. To clean up:
    ```sh
    terraform apply -destroy
    ```