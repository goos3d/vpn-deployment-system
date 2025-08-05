# QUICK CONNECTION TEST

## For Dr. Kover (Client Side):
1. Import dr_kover.conf into WireGuard
2. Click "Activate"
3. Check: Status shows "Active" (green)
4. Verify: IP shows 10.0.0.3

## For Server Admin (VM Side):
1. Run VM_VALIDATION_TEST.ps1 on Windows VM
2. Verify all tests pass ✅
3. Confirm port 51820 listening
4. Check WireGuard service running

## Success Criteria:
- ✅ Client connects in < 10 seconds
- ✅ Gets IP 10.0.0.3
- ✅ Practice systems accessible
- ✅ Internet speed unaffected
- ✅ No security warnings

Security Code: 369086
