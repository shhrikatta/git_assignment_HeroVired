# Calculator Plus App - Version 1.0.0

A Python-based calculator application that provides basic arithmetic operations with future support for advanced mathematical functions.

## Overview

The Calculator Plus app is a simple yet extensible calculator built in Python. It currently supports fundamental arithmetic operations and has been designed with future enhancements in mind, including square root calculations.

## Features

### Current Features (v1.0.0)
- **Addition**: Add two numbers
- **Subtraction**: Subtract one number from another
- **Multiplication**: Multiply two numbers
- **Division**: Divide one number by another with error handling for division by zero
- **Square Root**: Calculate the square root of a number

### Geometry Features (Latest)
- **Circle Area Calculation**: Calculate the area of a circle using radius
- **Rectangle Area Calculation**: Calculate the area of a rectangle using length and width

### Planned Features

## Installation & Usage

### Prerequisites
- Python 3.x
- math module (included in Python standard library)

### Running the Application

#### Basic Calculator
```bash
python CalculatorPlus.py
```

#### Geometry Calculator
```bash
python area.py
```

### Example Output

#### Calculator Output
```
16 + 4 = 20
16 - 4 = 12
16 * 4 = 64
16 / 4 = 4.0
The square root of 25 = 5.0
```

#### Geometry Calculator Output
```
The area of the circle with radius 5 = 78.53981633974483
The area of the rectangle with length 10 and width 6 = 60
```

## Code Structure

### Calculator Class
```python
class Calculator:
    def add(self, a, b):
        return a + b
    
    def subtract(self, a, b):
        return a - b
    
    def multiply(self, a, b):
        return a * b
    
    def divide(self, a, b):
        if b == 0:
            raise ValueError("Cannot divide by zero.")
        return a / b
    
    def sqrt(self, x):
        return math.sqrt(x)
```

### GeometryCalculator Class
```python
class GeometryCalculator:
    def calculate_circle_area(self, radius):
        return math.pi * radius ** 2
    
    def calculate_rectangle_area(self, length, width):
        return length * width
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

### Recent Development Updates (Post v1.0.0)

After the v1.0.0 release, significant enhancements have been made on multiple feature branches:

#### Latest Update: Geometry Calculator (feature/circle-area)

**Latest Commit:**
```
2e90090 (HEAD -> feature/circle-area, origin/feature/circle-area) feat: add GeometryCalculator for area calculations of circle and rectangle
```

**New Features Added:**
1. **GeometryCalculator Class** - A new class dedicated to geometry calculations
2. **Circle Area Calculation** - Calculate area using π × radius²
3. **Rectangle Area Calculation** - Calculate area using length × width
4. **Interactive Examples** - Demonstrative calculations with sample values

#### Previous Updates: Square Root Feature (feature/sqrt)

Significant enhancements were made on the `feature/sqrt` branch:

#### Feature Branch: `feature/sqrt`

**Commit History:**
```
a76f65c (HEAD -> feature/sqrt, origin/feature/sqrt) fix: fixed format issues
fcc1ea9 fix: fixed divide error if denominator is 0 to raise value error
4038685 feat: added square root log implementation
```

#### New Features Implemented:

1. **Square Root Functionality** (Commit: `4038685`)
   - Implemented the `sqrt()` method using `math.sqrt()`
   - Added square root calculation to the example output
   - Feature is now fully functional and tested

2. **Division by Zero Error Handling** (Commit: `fcc1ea9`)
   - Enhanced the `divide()` method with proper error handling
   - Raises `ValueError` when attempting to divide by zero
   - Improves application stability and user experience

3. **Code Formatting Improvements** (Commit: `a76f65c`)
   - Fixed formatting issues in the codebase
   - Improved code readability and consistency

#### Current Status:
- These features are ready for integration into the main branch
- All planned v1.1.0 features have been successfully implemented
- The feature branch is ahead of main by 3 commits

## Future Development

### Upcoming Features
1. **Extended Operations**: Power, logarithm, trigonometric functions
2. **More Geometric Shapes**: Triangle, trapezoid, ellipse area calculations
3. **Volume Calculations**: Sphere, cylinder, cube volume calculations
4. **User Interface**: Interactive CLI or GUI interface
5. **Input Validation**: Validate user inputs for mathematical operations
6. **Scientific Calculator Mode**: Advanced mathematical functions and constants

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
├── area.py             # Geometry calculator for area calculations
├── README.md           # Project documentation
└── .git/              # Git version control
```

## License

This project is part of the HeroVired Git assignment.

---

**Calculator Plus App v1.0.0** - A simple, extensible Python calculator
