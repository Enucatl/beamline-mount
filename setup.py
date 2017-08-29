# pylint: disable=all

from setuptools import setup, find_packages


setup(
    name="sls_scripts",
    version="v1.0.0",
    packages=find_packages(exclude='test'),
    install_requires=[
        'click',                                                                                                                                  
    ],
    package_data={
        # If any package contains *.txt or *.rst files, include them:
        '': ['*.txt', '*.rst', 'src/arg.so'],
    },
    # metadata for upload to PyPI
    author="Matteo Abis",
    author_email="",
    description="Scripts to mount SLS resources",
    license="GNU GPL 3",
    keywords="",
    # project home page, if any
    url="https://github.com/Enucatl/beamline-mount",
    entry_points="""
    [console_scripts]
    blmount = bin.blmount:main
    """
    # could also include long_description, download_url, classifiers, etc.
)
