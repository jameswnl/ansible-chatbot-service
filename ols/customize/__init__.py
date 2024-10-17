import os
import importlib

project = os.getenv('PROJECT', 'ols')
prompts = importlib.import_module(f'ols.customize.{project}.prompts')
keywords = importlib.import_module(f'ols.customize.{project}.keywords')
