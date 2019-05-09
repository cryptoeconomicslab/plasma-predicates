@public
@constant
def verify_update(
  state_update: bytes[256],
  subject: address,
  state_update_witness: bytes[512]
) -> bool:
  return True
