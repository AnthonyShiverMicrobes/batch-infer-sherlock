import os
import sys
import argparse
from Bio import SeqIO
import pandas as pd

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'workflow', 'rules'))
from common import alphafold3_jobname, alphafold3_write_monomer, printsrc


def extract_proteins_from_genbank(genbank_path, output_dir='orf'):
    """
    Parse GenBank file and extract all protein-coding ORFs.

    Args:
        genbank_path: Path to GenBank (.gb or .gbk) file
        output_dir: Directory to write JSON files (default: alphafold3_jsons)

    Returns:
        List of protein records processed
    """
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    # Track original working directory
    original_dir = os.getcwd()

    # Parse GenBank file
    records_processed = []
    total_proteins = 0

    printsrc(f"Reading GenBank file: {genbank_path}")

    for genome_record in SeqIO.parse(genbank_path, "genbank"):
        genome_id = genome_record.id
        printsrc(f"Processing genome: {genome_id} ({genome_record.description})")

        # Extract all CDS features with translations
        for feature in genome_record.features:
            if feature.type == "CDS":
                # Try to get protein sequence
                protein_seq = None

                # First try to get translation directly
                if "translation" in feature.qualifiers:
                    protein_seq = feature.qualifiers["translation"][0]

                # Skip if no protein sequence available
                if not protein_seq:
                    continue

                # Generate protein ID
                # Priority: locus_tag > protein_id > gene > location
                if "locus_tag" in feature.qualifiers:
                    protein_id = feature.qualifiers["locus_tag"][0]
                elif "protein_id" in feature.qualifiers:
                    protein_id = feature.qualifiers["protein_id"][0]
                elif "gene" in feature.qualifiers:
                    protein_id = feature.qualifiers["gene"][0]
                else:
                    # Use location as fallback
                    protein_id = f"{genome_id}_{feature.location.start}_{feature.location.end}"

                # Get product name if available
                product = ""
                if "product" in feature.qualifiers:
                    product = feature.qualifiers["product"][0]

                # Create AF3-compatible ID
                af3_id = alphafold3_jobname(f"{genome_id}_{protein_id}")

                # Write JSON file using common.py function
                # Temporarily change to output directory
                os.chdir(output_dir)
                alphafold3_write_monomer(af3_id, protein_seq)
                os.chdir(original_dir)

                # Track results
                records_processed.append({
                    'af3_id': af3_id,
                    'original_id': protein_id,
                    'genome': genome_id,
                    'product': product,
                    'length': len(protein_seq),
                    'location': str(feature.location)
                })
                total_proteins += 1

                if total_proteins % 100 == 0:
                    printsrc(f"Processed {total_proteins} proteins...")

    printsrc(f"Total proteins extracted: {total_proteins}")
    printsrc(f"JSON files written to: {output_dir}")

    return records_processed


def parse_arguments():
    """
    Parse command line arguments.

    Returns:
        argparse.Namespace: Parsed arguments
    """
    parser = argparse.ArgumentParser(
        description='Convert GenBank protein ORFs to AlphaFold3 JSON format'
    )
    parser.add_argument(
        'genbank_file',
        help='Path to GenBank file (.gb or .gbk)'
    )
    parser.add_argument(
        '--output-dir',
        default='alphafold3_jsons',
        help='Output directory for JSON files (default: alphafold3_jsons)'
    )
    parser.add_argument(
        '--summary',
        help='Optional path to write summary CSV file'
    )

    args = parser.parse_args()

    # Check if input file exists
    if not os.path.isfile(args.genbank_file):
        print(f"Error: File not found: {args.genbank_file}", file=sys.stderr)
        sys.exit(1)

    return args


def main():
    args = parse_arguments()

    # Process GenBank file
    records = extract_proteins_from_genbank(args.genbank_file, args.output_dir)

    # Optionally write summary
    if args.summary:
        df = pd.DataFrame(records)
        df.to_csv(args.summary, index=False)
        printsrc(f"Summary written to: {args.summary}")

    print(f"\nSuccessfully processed {len(records)} proteins")
    print(f"JSON files are in: {args.output_dir}/")


if __name__ == '__main__':
    main()