from setuptools import setup

with open("README.md", 'r') as f:
    long_description = f.read()

setup(
    name='mimasdriver',
    version='1.0.0',
    description='Driver for custom Mimas V1 firmware',

    author='Joppe Blondel',
    author_email='joppe@blondel.nl',
    download_url='',
    url='https://github.com/Jojojoppe/qandaomr',

    keywords = ['Mimas', 'USB programmer',],
    classifiers=[
        'Development Status :: 3 - Alpha',
        'License :: OSI Approved :: BSD License',
        'Programming Language :: Python :: 3',
  ],

    packages=['mimasdriver'],
    licence='BSD Licence',
    install_requires=['libusb1',],
    scripts=['scripts/mimasprog', 'scripts/mimastransfer']
)