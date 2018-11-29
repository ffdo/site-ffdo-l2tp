#!/usr/bin/env python3

import argparse
import shutil
import os
import logging
import yaml
from jinja2 import Environment, FileSystemLoader
from pathlib import Path

def init_output_dir(common_dir, output_dir):
    logging.info("Deleting output folder '{}', if it exists".format(output_dir))
    shutil.rmtree(output_dir, ignore_errors = True)
    logging.info("Copying the common folder '{}' into the newly created output folder '{}'".format(common_dir, output_dir))
    # the destination directory must not exist here
    shutil.copytree(common_dir, output_dir)

def write_site_files(template_dir, domain_config, output_dir):
    logging.info("Populating templates from '{}' and writing it into '{}'".format(template_dir, output_dir))
    env = Environment(loader=FileSystemLoader(template_dir))
    template_paths = Path(template_dir).glob('**/*')
    for template_path in template_paths:
        template_file = str(template_path.relative_to(template_dir))
        logging.info("Applying data to template '{}'".format(template_file))
        template = env.get_template(template_file)
        template.stream(domain_config).dump(os.path.join(output_dir, template_file))

def get_domain_config(domain_file):
    logging.info("Loading domain config file '{}'".format(domain_file))
    with open(domain_file) as f:
        data = yaml.load(f)
    return data

def main(args):
    init_output_dir(args.common_dir, args.output_dir)
    domain_config = get_domain_config(args.domain_file)
    write_site_files(args.template_dir, domain_config, args.output_dir)

if __name__ == "__main__":
    #logging.basicConfig(level=logging.DEBUG)
    parser = argparse.ArgumentParser()
    parser.add_argument("template_dir", help="The directory containing the templates")
    parser.add_argument("common_dir", help="The directory containing the common (unchanged) files")
    parser.add_argument("domain_file", help="The file containing the domain settings")
    parser.add_argument("output_dir", help="The ouptput directory")
    args = parser.parse_args()
    main(args)
