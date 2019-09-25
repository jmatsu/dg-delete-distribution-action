# Delete a distribution from DeployGate

This action deletes a *distribution* from DeployGate on branch-delete. (Not official action of DeployGate.)

## Versions

See [Releases](https://github.com/jmatsu/dg-delete-distribution-action/releases) page.

## Inputs and Outpus

See *action.yml* of your version.

## Example

Please make sure your workflow will run when a ref is deleted.

```
on:
  delete
```

Add this action to steps.

```
uses: jmatsu/dg-delete-distribution-action@<version>
  with:
    app_owner_name: <your DeployGate account/organization name>
    platform: <android|ios>
    app_id: <package name|bundle identifier>
    api_token: ${{ secrets.DEPLOYGATE_API_TOKEN }} # for example
  env:
    DEBUG: true # keep true iff you want to see logs
```

For more detail, please read *action.yml* and [workflow examples](.github/workflows)

## License

[MIT License](LICENSE)