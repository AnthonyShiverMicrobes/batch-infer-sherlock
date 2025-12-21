
rule msa:
    """
    Run AF3 data pipeline for one input .json
    """
    input:
        json = 'orf/{id}.json',
    output:
        json = 'msa/{id}_data.json.gz',
    params:
        # bind paths
        af_input = '--bind orf:/root/af_input',
        af_output = '--bind msa:/root/af_output',
        models = f'--bind {config["models"]}:/root/models',
        databases = f'--bind {config["databases"]}:/root/public_databases',
        #databases_fallback = f'--bind {config["alphafold3_databases_fallback"]}:/root/public_databases_fallback',
        docker = root_path(config['docker']),
        # run_alphafold.py
        json_path = lambda wc: f'--json_path=/root/af_input/{wc.id}.json',
        output_dir = '--output_dir=/root/af_output',
        model_dir ='--model_dir=/root/models',
        db_dir = '--db_dir=/root/public_databases',
        #db_dir_fallback = '--db_dir=/root/public_databases_fallback',
        xtra_args = '--norun_inference',
    envmodules:
        'stack/2024-06', 'python/3.11.6',
    # https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#defining-retries-for-fallible-rules
    # Re-attempt (failed) MSAs with increasing runtimes (4h, 1d, 3d)
    retries: 3
    shell: """
        SMKDIR=`pwd`
        rsync -auq $SMKDIR/ $TMPDIR --include='orfs' --include='{input.json}' --exclude='*'
        mkdir -p $TMPDIR/msas
        cd $TMPDIR
        singularity exec {params.af_input} {params.af_output} {params.models} {params.databases} {params.docker} \
            sh -c 'python /app/alphafold/run_alphafold.py \
                {params.json_path} \
                {params.output_dir} \
                {params.model_dir} \
                {params.db_dir} \
                {params.xtra_args}'
        cd -
        gzip $TMPDIR/msas/{wildcards.id}/{wildcards.id}_data.json
        cp $TMPDIR/msas/{wildcards.id}/{wildcards.id}_data.json.gz $SMKDIR/msas/{wildcards.id}_data.json.gz
    """
