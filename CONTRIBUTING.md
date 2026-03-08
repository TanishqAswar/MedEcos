# Contributing to MedEcos

Thank you for your interest in contributing to MedEcos! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/MedEcos.git
   cd MedEcos
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. Create a `.env` file based on `.env.example`
5. Start MongoDB and run the development server:
   ```bash
   npm run dev
   ```

## Development Workflow

1. Create a new branch for your feature or bug fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the coding standards

3. Test your changes:
   ```bash
   npm test
   ```

4. Commit your changes with a descriptive message:
   ```bash
   git commit -m "Add feature: description of your changes"
   ```

5. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

6. Open a Pull Request

## Coding Standards

### JavaScript Style Guide

- Use ES6+ features
- Use async/await for asynchronous operations
- Follow consistent naming conventions:
  - camelCase for variables and functions
  - PascalCase for models and classes
  - UPPER_SNAKE_CASE for constants

### File Organization

- **models/**: Database models (Mongoose schemas)
- **routes/**: API route handlers
- **middleware/**: Express middleware functions
- **config/**: Configuration files
- **tests/**: Test files
- **examples/**: Example scripts and demos

### API Design

- Follow RESTful principles
- Use appropriate HTTP methods (GET, POST, PUT, DELETE)
- Return appropriate status codes
- Include error handling in all routes
- Validate input data

### Error Handling

```javascript
try {
  // Your code here
} catch (error) {
  res.status(500).json({ error: error.message });
}
```

### Authentication

- Protect routes with the `auth` middleware
- Use `authorize()` middleware for role-based access
- Always validate user permissions

## Database Models

When adding new models:

1. Create the model in the `models/` directory
2. Use appropriate data types and validation
3. Add indexes for frequently queried fields
4. Include timestamps where appropriate

## API Routes

When adding new routes:

1. Create route file in the `routes/` directory
2. Import necessary models and middleware
3. Implement proper error handling
4. Add authentication where needed
5. Document the endpoint in API_DOCS.md

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm test -- --watch

# Run tests with coverage
npm test -- --coverage
```

### Writing Tests

- Write tests for all new features
- Test both success and error cases
- Use descriptive test names
- Mock external dependencies when appropriate

Example test structure:
```javascript
describe('Feature Name', () => {
  test('should do something', async () => {
    // Arrange
    const data = { /* test data */ };
    
    // Act
    const result = await someFunction(data);
    
    // Assert
    expect(result).toBe(expectedValue);
  });
});
```

## Documentation

- Update README.md for major changes
- Update API_DOCS.md for API changes
- Add comments for complex logic
- Keep documentation in sync with code

## Pull Request Guidelines

### Before Submitting

- [ ] Code follows the style guidelines
- [ ] Tests pass locally
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] No console.log statements (use proper logging)
- [ ] No commented-out code

### PR Description

Include in your PR description:

1. **What**: Brief description of changes
2. **Why**: Reason for the changes
3. **How**: Technical approach
4. **Testing**: How you tested the changes
5. **Screenshots**: If applicable

### PR Title Format

- `feat: Add user profile feature`
- `fix: Resolve authentication bug`
- `docs: Update API documentation`
- `test: Add tests for appointments`
- `refactor: Improve error handling`

## Issue Reporting

### Bug Reports

Include:
- Clear description of the bug
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details (OS, Node version, etc.)

### Feature Requests

Include:
- Clear description of the feature
- Use case and benefits
- Possible implementation approach

## Code Review Process

1. All PRs require review before merging
2. Address review comments
3. Ensure CI/CD checks pass
4. Squash commits if requested

## Community

- Be respectful and constructive
- Follow the code of conduct
- Help others when possible
- Share knowledge and best practices

## Questions?

If you have questions, please:
- Check existing documentation
- Search for existing issues
- Create a new issue with the "question" label

## License

By contributing, you agree that your contributions will be licensed under the project's MIT License.

---

Thank you for contributing to MedEcos! 🏥
