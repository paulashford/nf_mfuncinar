from setuptools import setup
import os

# see https://setuptools.pypa.io/en/latest/userguide/quickstart.html
# for setuptools info
# fvp is based on project structure of cath-alphaflow and uses a basic, custom nf-core pipeline initialisation
# NOTE: cath-alphaflow dependency via release tag 0.0.1: https://github.com/UCLOrengoGroup/cath-alphaflow/releases/tag/v0.0.1
# dependency via URL as per: https://peps.python.org/pep-0440/#direct-references from here: https://setuptools.pypa.io/en/stable/userguide/dependency_management.html
# pip install git+https://github.com/UCLOrengoGroup/cath-alphaflow/releases/tag/v0.0.1  (a pip VCS reference)
# tag v0.0.1 refs this commit hash:
# https://github.com/UCLOrengoGroup/cath-alphaflow/commit/37ef75f65230ef98aa017400ecc1b01ac355553e
# in pep-0440 form:
# cath-alphaflow @ git+https://github.com/UCLOrengoGroup/cath-alphaflow.git@v0.0.1#37ef75f65230ef98aa017400ecc1b01ac355553e
# cath-alphaflow @ git+https://github.com/pypa/pip.git@1.3.1#7921be1537eac1e97bc40179a57f0349c2aee67d

VERSION = "0.1"

def get_long_description():
    with open(
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "README.md"),
        encoding="utf8",
    ) as fp:
        return fp.read()
# package_dir={"":"~/git/funvar/fvp"},
setup(
    name="macsr_nf_dev",
    description="MACSMAF NextFlow pipeline for parts of CSR protocol - eg func enrichment of modules (DEV)",
    long_description=get_long_description(),
    long_description_content_type="text/markdown",
    author=["Ash","Orengo group"],
    project_urls={
        "Issues": "https://github.com/paulashford/macsr_nf_dev/issues",
        "Changelog": "https://github.com/paulashford/macsr_nf_dev/issues/releases",
    },
    license="Apache License, Version 2.0",
    version=VERSION,
    packages=["macsr_nf_dev"],
    entry_points="""
        [console_scripts]
        macsr_nf_dev=macsr_nf_dev.cli:cli
    """,
    install_requires=[
        # "cath-alphaflow @ git+https://github.com/UCLOrengoGroup/cath-alphaflow.git@v0.0.1#37ef75f65230ef98aa017400ecc1b01ac355553e"
        "click",
        # "oracledb",
        "prettyconf",
        "biopython",
        "pdb-tools",
        "pydantic",
        "pandas",
	"goatools",
        # "gcloud"
    ],
    extras_require={"test": ["pytest"]},
    python_requires=">=3.7",
)
