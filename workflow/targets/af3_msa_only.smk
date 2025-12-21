
ids, = glob_wildcards('orfs/{id}.json')

include: '../rules/common.smk'
include: '../rules/msa.smk'

rule af3_msa_only:
    input:
        expand('msas/{id}_data.json.gz', id=ids),
