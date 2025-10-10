# Calculator Plus App - Version 1.0.0

A Python-based calculator application that provides basic arithmetic operations with future support for advanced mathematical functions.

## Overview

The Calculator Plus app is a simple yet extensible calculator built in Python. It currently supports fundamental arithmetic operations and has been designed with future enhancements in mind, including square root calculations.

## Features

### Current Features (v1.0.0)
- **Addition**: Add two numbers
- **Subtraction**: Subtract one number from another
- **Multiplication**: Multiply two numbers
- **Division**: Divide one number by another

### Planned Features
- **Square Root**: Calculate the square root of a number (implementation ready, commented out)

## Installation & Usage

### Prerequisites
- Python 3.x
- math module (included in Python standard library)

### Running the Application

```bash
python CalculatorPlus.py
```

### Example Output
```
16 + 4 = 20
16 - 4 = 12
16 * 4 = 64
16 / 4 = 4.0
```

## Code Structure

```python
class Calculator:
    def add(self, a, b):
        return a + b
    
    def subtract(self, a, b):
        return a - b
    
    def multiply(self, a, b):
        return a * b
    
    def divide(self, a, b):
        return a / b
    
    # Future feature - Square root (commented out)
    # def square_root(self, x):
    #     return math.sqrt(x)
```

## Development Workflow & Release Process

### Branch Structure
- `main`: Production-ready code
- `dev`: Development branch for new features

### Version 1.0.0 Release Process

The following steps were completed to merge the development branch and create the first official release:

#### Step 1: Commit Development Changes
```bash
# Add the Calculator Plus app to version control
git add CalculatorPlus.py
git commit -m "Add Calculator Plus app with basic arithmetic operations"
```

#### Step 2: Prepare Main Branch
```bash
# Switch to main branch
git checkout main

# Ensure main branch is up to date
git pull origin main
```

#### Step 3: Merge Development Branch
```bash
# Merge dev branch into main (fast-forward merge)
git merge dev
```
**Result**: Successfully merged with fast-forward (no conflicts)

#### Step 4: Create Release Tag
```bash
# Create annotated tag for version 1.0.0
git tag -a v1.0.0 -m "Release version 1.0.0 of Calculator Plus App"
```

#### Step 5: Push to Remote Repository
```bash
# Push merged changes to main
git push origin main

# Push the release tag
git push origin v1.0.0
```

### Release Information
- **Version**: 1.0.0
- **Release Date**: October 10, 2025
- **Tag**: `v1.0.0`
- **Commit Hash**: `b8bdb29`
- **Release Notes**: Initial release with basic arithmetic operations

### Git History
```
b8bdb29 (HEAD -> main, tag: v1.0.0, origin/main, dev) Add Calculator Plus app with basic arithmetic operations
f398d6b Initial commit
```

## Future Development

### Upcoming Features
1. **Square Root Functionality**: Uncomment and test the `square_root` method
2. **Error Handling**: Add proper exception handling for division by zero
3. **Extended Operations**: Power, logarithm, trigonometric functions
4. **User Interface**: Interactive CLI or GUI interface

### Contributing

1. Create a feature branch from `dev`
2. Implement your changes
3. Test thoroughly
4. Create a pull request to merge into `dev`
5. After review, changes will be merged to `main` for the next release

### Development Commands

```bash
# Clone the repository
git clone https://github.com/shhrikatta/git_assignment_HeroVired.git
cd git_assignment_HeroVired

# Create a new feature branch
git checkout -b feature/your-feature-name

# Make changes and commit
git add .
git commit -m "Your commit message"

# Push feature branch
git push origin feature/your-feature-name
```

## Project Structure

```
git_assignment_HeroVired/
├── CalculatorPlus.py    # Main calculator application
├── README.md           # Project documentation
└── .git/              # Git version control
```

## License

This project is part of the HeroVired Git assignment.

---

**Calculator Plus App v1.0.0** - A simple, extensible Python calculator
