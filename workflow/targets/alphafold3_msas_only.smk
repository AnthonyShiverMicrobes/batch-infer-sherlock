
ids, = glob_wildcards('orfs/{id}.json')

include: '../rules/common.smk'
include: '../rules/msa.smk'

rule alphafold3_msas_only:
    input:
        expand('msas/{id}_data.json.gz', id=ids),
