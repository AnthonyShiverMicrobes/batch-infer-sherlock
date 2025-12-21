# Fork of batch-infer Batch inference of protein structure

A fork of batch-infer, written by jurgjn, modified for deployment on Stanford's sherlock cluster for CPU-based MSA generation. Original readme quoted below.

>Run AlphaFold3 on [Euler](https://scicomp.ethz.ch/wiki/Getting_started_with_clusters) at scale with data pipeline (MSA), >and structure prediction steps parallelised across nodes. As an example, the _e. coli_ reference proteome has 4,402 >monomers. The data pipeline steps took 2 days with up to 500 CPU jobs running simultaneously. The structure prediction steps took ~4 hours with ~15 GPU jobs running simultaneously. A small number of inputs [failed/had to be re-run](results/alphafold3_ecoli/README.md).
>- Data pipeline runs on CPU-only nodes, each input as a separate job. Runtime per input ranges from an hour to a few days. Jobs that run out of RAM/runtime automatically re-start with increased resources.
>- Structure prediction runs on nodes with an A100 GPU, typically taking minutes per input. The runtime is predictable from the
[number of input tokens](results/alphafold3_runtime/af3_predict_runtime.ipynb).
>We can use this to group inputs by size, and run one structure prediction job per group. This minimizes model startup, recompilation, and job scheduler waiting time.
>- Uses [local scratch](https://scicomp.ethz.ch/wiki/Using_local_scratch), compresses input/output with gzip (~5x space/traffic reduction).
>- Can use monomer data pipeline output to generate the input for multimer structure prediction. This can speed up interaction screens, e.g. protein-protein or protein-ligand...
