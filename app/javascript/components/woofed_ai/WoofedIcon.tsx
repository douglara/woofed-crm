import woofedIcon from '@/images/woofed-icon.svg'

// The Woofed mark inside a purple circle — the assistant's avatar.
const WoofedIcon = ({ size = 34 }: { size?: number }) => (
  <div
    className="flex shrink-0 items-center justify-center overflow-hidden rounded-full border-[1.5px] color-border-harder color-bg-fill-hard"
    style={{ width: size, height: size }}
  >
    <img
      src={woofedIcon}
      alt="Woofed AI"
      style={{ width: size * 0.62, height: size * 0.62 }}
      className="object-contain"
    />
  </div>
)

export default WoofedIcon
