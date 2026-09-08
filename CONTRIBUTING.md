# Contributing to NetBird OpenWrt Exit Node Guide

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

- Be respectful and inclusive
- Welcome diverse perspectives
- Focus on constructive feedback
- Report issues professionally

## How to Contribute

### 1. Reporting Issues

Found a problem or have a suggestion? Open an issue!

**When reporting an issue, please include:**
- Your OpenWrt version
- Your router model
- NetBird version (run `netbird version`)
- Clear description of the problem
- Steps to reproduce (if applicable)
- Error messages or logs (use code blocks)
- What you expected vs. what happened

**Example issue:**
```
Title: netbird wt0 interface not getting IP address

Environment:
- OpenWrt 21.02
- TP-Link WR841N
- NetBird v0.23.0

Problem:
After running all setup commands, the wt0 interface exists but has no IP address.

Steps to reproduce:
1. Run installation steps 1-3
2. Run dashboard configuration
3. Check with `ip addr show wt0`

Expected: inet 100.x.x.x/16
Actual: No address assigned
```

### 2. Suggesting Improvements

Have a suggestion to make the guide better?

- Open an issue with the label `enhancement`
- Describe what could be improved
- Explain why it would help
- Provide examples if possible

### 3. Submitting Changes

#### Fork & Clone
```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/netbird-openwrt-guide.git
cd netbird-openwrt-guide
```

#### Create a Branch
```bash
git checkout -b fix/your-fix-name
# or
git checkout -b feature/your-feature-name
```

#### Make Changes
- Edit the relevant files
- Test your changes thoroughly
- Follow the style guidelines (see below)

#### Commit & Push
```bash
git add .
git commit -m "Concise description of changes"
git push origin fix/your-fix-name
```

#### Open a Pull Request
1. Go to the original repository
2. Click "New Pull Request"
3. Select your branch
4. Write a clear PR description
5. Submit!

## Style Guidelines

### Markdown Format
- Use clear headings with proper hierarchy (H2 for sections, H3 for subsections)
- Code blocks with language specification: ` ```bash `
- Inline code for commands/variables: `` `netbird status` ``
- Use bold for UI elements: `**Dashboard**`
- Use italics for placeholders: `*your_wan_interface*`

### Command Documentation
- Each command should have:
  - Brief description of what it does
  - The actual command
  - Expected output (when relevant)
  - Warning/note if it's critical

**Example:**
```markdown
### Enable IP Forwarding

Check your current setting:

\`\`\`bash
sysctl net.ipv4.ip_forward
\`\`\`

Expected output: `net.ipv4.ip_forward = 1`

If it shows `0`, enable it:

\`\`\`bash
sysctl -w net.ipv4.ip_forward=1
\`\`\`

**What this does:** Allows your router to forward packets between networks.
```

### Troubleshooting Entries
Format:
- **Issue title** (what the problem looks like)
- **Symptoms** (how you know you have this problem)
- **Solutions** (commands and steps to fix it)

### Code Blocks
```bash
# Always use bash for OpenWrt commands
# Add comments to explain complex steps
# Use clear variable names
```

## Content Types & Locations

| Content | File | Format |
|---------|------|--------|
| Main guide | README.md | Markdown |
| Automation script | setup.sh | Bash |
| Contributions guide | CONTRIBUTING.md | Markdown |
| License | LICENSE | Plain text |
| Troubleshooting | README.md (section) | Markdown |
| FAQ | README.md (section) | Markdown |

## Common Contributions

### Adding a Troubleshooting Section

If you've solved a problem not covered:

1. Add to the "Testing & Troubleshooting" section
2. Use the format:
   ```markdown
   #### Issue: Your Issue Title
   
   **Symptoms:** What you observe
   
   **Solutions:**
   \`\`\`bash
   # Command 1
   # Command 2
   \`\`\`
   
   Explanation of what this does.
   ```

### Updating for New OpenWrt Versions

1. Test with the new OpenWrt version
2. Update version number in README
3. Document any changes needed
4. Add compatibility note if version-specific

### Improving Documentation

1. Fix typos and grammar
2. Clarify confusing sections
3. Add examples or diagrams
4. Update outdated information

## Testing Your Changes

Before submitting:

1. **Read for clarity:**
   - Do instructions flow logically?
   - Are commands clear and complete?
   - Are there typos or grammar issues?

2. **Test if possible:**
   - Follow the guide on test hardware
   - Verify all commands work
   - Check all links are valid

3. **Validate formatting:**
   - Code blocks render correctly
   - Links work
   - Tables display properly
   - Lists are properly formatted

## PR Review Process

### What we look for:
- ✅ Clear, accurate instructions
- ✅ Tested content (if possible)
- ✅ Proper formatting
- ✅ Helpful explanations
- ✅ No security risks
- ✅ Addresses the issue/feature

### What might cause rejection:
- ❌ Unverified instructions
- ❌ Promoting paid services
- ❌ Security vulnerabilities
- ❌ Inappropriate content
- ❌ Spam or irrelevant changes

## Questions?

- 💬 Open a Discussion on GitHub
- 📧 Check existing issues for similar questions
- 📚 Review the FAQ section

## Recognition

Contributors will be:
- Mentioned in the README
- Credited in commit messages
- Part of the community

## Legal

By contributing, you agree that:
- Your contributions can be used under the MIT License
- You have the right to contribute the content
- Your contribution doesn't violate any intellectual property rights

---

Thank you for making this guide better! 🙏

**Happy contributing!**
