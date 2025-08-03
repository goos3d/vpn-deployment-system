# 🔄 Claude Follow-up Prompts

Use these follow-up prompts once Claude provides the initial VPN configuration.

## After Initial Config Generation

```
Great! The configs look good. Now I need help with:

1. **Testing the setup** - What commands should I run to verify:
   - VPN server is running correctly
   - Client can connect
   - Traffic is routing through VPN
   - DNS leaks are prevented

2. **Troubleshooting guide** - Common Windows VPN issues and fixes:
   - Connection timeouts
   - Firewall blocking
   - DNS not working
   - Performance optimization

3. **Client handoff package** - Create a simple guide for Dr. Kover:
   - How to install VPN client
   - How to import the config
   - How to connect/disconnect
   - How to verify secure connection

Keep it dental-practice friendly (non-technical language).
```

## For Advanced Configuration

```
Perfect! The basic setup works. Now let's optimize for the dental practice:

1. **Split tunneling** - Can we route only specific traffic through VPN?
   - Optima software traffic
   - OpenDental traffic  
   - Keep general web browsing local for speed

2. **Multiple clients** - How do I add more devices?
   - Dr. Kover's iPad
   - Office manager laptop
   - Backup workstation

3. **Monitoring** - What's the best way to:
   - See who's connected
   - Monitor bandwidth usage
   - Check connection logs (HIPAA-compliant)

4. **Backup and recovery** - How to backup the VPN config and restore if needed?
```

## For Security Hardening

```
The VPN is working great! Now let's lock it down for HIPAA compliance:

1. **Security audit** - Review the current config for:
   - Encryption strength
   - Authentication methods  
   - Logging policies
   - Access controls

2. **Compliance features** - What additional security measures should I add?
   - Certificate-based authentication
   - Two-factor authentication
   - Connection time limits
   - IP whitelisting

3. **Documentation** - Create compliance documentation showing:
   - Encryption methods used
   - Security controls implemented
   - Access logging procedures
   - Incident response plan

This needs to pass a HIPAA audit for a dental practice.
```

## For Performance Optimization

```
The VPN works but seems slow. Help me optimize for dental software:

1. **Performance tuning** - What settings can improve speed?
   - MTU optimization
   - Compression settings
   - Protocol selection
   - Server location considerations

2. **Bandwidth management** - How to:
   - Prioritize dental software traffic
   - Limit bandwidth per client
   - Monitor usage patterns

3. **Load testing** - How to test with multiple concurrent users?
   - Simulate office usage
   - Identify bottlenecks
   - Plan for growth

The dental software needs to be responsive during patient appointments.
```

---

**Usage:** Copy the relevant prompt based on what you need help with next. Each prompt builds on the previous work and maintains context about the dental practice requirements.
