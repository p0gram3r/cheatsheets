1. Store the vault password in some file, e.g. `vault.passwd`. Make sure to add it to `.gitnignore`,
 too!
    ```
    echo "mySuuperSecretVaultPassword" > vault.passwd
    echo "vault.passwd" >> .gitignore
    ```

2. Add a `.gitattributes` file to your repository. It must contain a filter that matches any ansible-vault encrypted 
files. Set the attribute `diff=ansible-vault`. It is also good to add `merge=binary` to prevent git from 3-way merging 
of encrypted files.
    ```
    environments/*/group_vars/all/vault.yaml diff=ansible-vault merge=binary
    ```

3. Update the project's git configuration to use `ansible-vault view` as diff driver for all files with attribute 
`diff=ansible-vault`.
    ```
    git config diff.ansible-vault.cachetextconv false
    git config diff.ansible-vault.textconv "ansible-vault view --vault-password-file=vault.passwd"
    ```

If the project requires different passwords for different vaults, simply add more `--vault-password-file` parameters.


Source: 
- https://stackoverflow.com/questions/29937195/how-to-diff-ansible-vault-changes
- https://github.com/building5/ansible-vault-tools 
- https://victorkoronen.se/2017/07/07/merging-ansible-vaults-in-git/
