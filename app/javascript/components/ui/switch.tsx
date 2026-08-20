"use client";

import type { ComponentProps } from "react";

import { cn } from "@/lib/utils";

interface SwitchProps
  extends Omit<ComponentProps<"input">, "type" | "onChange" | "className"> {
  checked: boolean;
  onCheckedChange: (checked: boolean) => void;
  className?: string;
}

/**
 * The toggle the settings screens use.
 *
 * It is built out of the same classes as the ERB one in
 * `accounts/settings/deals/edit.html.erb` rather than a fresh set, so the two
 * render identically and so it leans only on utilities Tailwind has already
 * compiled — a class that exists nowhere else needs the CSS rebuilt before it
 * does anything, and a switch that silently never leaves the off position is a
 * poor way to find that out.
 *
 * A hidden checkbox carries the state and the keyboard; the track beside it
 * reads that state through `peer-checked`. Unlike a checkbox it says which way
 * it is set without being compared against its neighbours, which is what the
 * setting deserves when it is the point of the row rather than one box on a
 * form.
 */
function Switch({
  checked,
  onCheckedChange,
  disabled,
  className,
  ...props
}: SwitchProps) {
  return (
    <label
      className={cn(
        "inline-flex items-center",
        disabled ? "cursor-not-allowed opacity-50" : "cursor-pointer",
        className,
      )}
    >
      <input
        type="checkbox"
        className="peer sr-only"
        checked={checked}
        disabled={disabled}
        onChange={(event) => onCheckedChange(event.target.checked)}
        {...props}
      />
      <div className="relative h-5 w-9 rounded-full bg-gray-400 after:absolute after:start-[2px] after:top-[2px] after:h-4 after:w-4 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:color-bg-fill-highlight peer-checked:after:translate-x-full peer-checked:after:border-white peer-focus:outline-none" />
    </label>
  );
}

export { Switch };
