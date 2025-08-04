from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="screenshot-intelligence",
    version="1.0.0",
    author="Thomas Rodriguez",
    author_email="thomas@eastbayav.com",
    description="A powerful OCR and pattern recognition system for technical screenshots",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/screenshot-intelligence-system",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Topic :: Scientific/Engineering :: Image Recognition",
        "Topic :: Text Processing :: Markup",
    ],
    python_requires=">=3.7",
    install_requires=[
        "pytesseract>=0.3.10",
        "Pillow>=9.0.0", 
        "click>=8.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=6.0",
            "pytest-cov>=2.0",
            "black>=21.0",
            "flake8>=3.8",
        ],
    },
    entry_points={
        "console_scripts": [
            "screenshot=screenshot.cli_integration:main",
        ],
    },
    include_package_data=True,
    package_data={
        "screenshot": ["*.md", "*.json"],
    },
)
