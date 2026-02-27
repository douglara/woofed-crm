import * as React from "react";
import { Button } from "@/components/ui/button";
import { Loader2 } from "lucide-react";
import { ArrowUpRightIcon } from "lucide-react";
import { CircleFadingArrowUpIcon } from "lucide-react";
import { ArrowUpIcon } from "lucide-react";
import { Spinner } from "@/components/ui/spinner";

import {
  ComboboxInput,
  Combobox,
  ComboboxChip,
  ComboboxChips,
  ComboboxChipsInput,
  ComboboxContent,
  ComboboxEmpty,
  ComboboxItem,
  ComboboxList,
  ComboboxValue,
  useComboboxAnchor,
} from "@/components/ui/combobox";
const frameworks = [
  "Next.js",
  "SvelteKit",
  "Nuxt.js",
  "Remix",
  "Astro",
] as const;

export default function Index() {
  const anchor = useComboboxAnchor();

  return (
    <div className="flex flex-col items-start gap-8 sm:flex-row m-5 flex-wrap">
      <div className="flex items-start gap-2">
        <Button size="xs" variant="outline">
          Extra Small
        </Button>
        <Button size="icon-xs" aria-label="Submit" variant="outline">
          <ArrowUpRightIcon />
        </Button>
      </div>
      <div className="flex items-start gap-2">
        <Button size="sm" variant="outline">
          Small
        </Button>
        <Button size="icon-sm" aria-label="Submit" variant="outline">
          <ArrowUpRightIcon />
        </Button>
      </div>
      <div className="flex items-start gap-2">
        <Button variant="outline">Default</Button>
        <Button size="icon" aria-label="Submit" variant="outline">
          <ArrowUpRightIcon />
        </Button>
      </div>
      <div className="flex items-start gap-2">
        <Button variant="outline" size="lg">
          Large
        </Button>
        <Button size="icon-lg" aria-label="Submit" variant="outline">
          <ArrowUpRightIcon />
        </Button>
      </div>
      <div className="flex items-start gap-2">
        <Button>Button</Button>
      </div>
      <div className="flex items-start gap-2">
        <Button variant="outline">Outline</Button>
      </div>
      <div className="flex items-start gap-2">
        <Button variant="secondary">Secondary</Button>
      </div>
      <div className="flex items-start gap-2">
        <Button variant="ghost">Ghost</Button>
      </div>
      <div className="flex items-start gap-2">
        <Button variant="destructive">Destructive</Button>
      </div>
      <div className="flex items-start gap-2">
        <Button variant="link">Link</Button>
      </div>
      <div className="flex items-start gap-2">
        <Button variant="outline" size="icon">
          <CircleFadingArrowUpIcon />
        </Button>
      </div>
      <div className="flex items-start gap-2">
        <Button variant="outline" size="sm">
          <ArrowUpIcon /> New Branch
        </Button>
      </div>
      <Button variant="outline" size="icon" className="rounded-full">
        <ArrowUpIcon />
      </Button>
      <div className="flex gap-2">
        <Button variant="outline" disabled>
          <Spinner data-icon="inline-start" />
          Generating
        </Button>
        <Button variant="secondary" disabled>
          Downloading
          <Spinner data-icon="inline-start" />
        </Button>
      </div>
      <Combobox items={frameworks}>
        <ComboboxInput placeholder="Select a framework" />
        <ComboboxContent>
          <ComboboxEmpty>No items found.</ComboboxEmpty>
          <ComboboxList>
            {(item) => (
              <ComboboxItem key={item} value={item}>
                {item}
              </ComboboxItem>
            )}
          </ComboboxList>
        </ComboboxContent>
      </Combobox>
      <Combobox
        multiple
        autoHighlight
        items={frameworks}
        defaultValue={[frameworks[0]]}
      >
        <ComboboxChips ref={anchor} className="w-full max-w-xs">
          <ComboboxValue>
            {(values) => (
              <React.Fragment>
                {values.map((value: string) => (
                  <ComboboxChip key={value}>{value}</ComboboxChip>
                ))}
                <ComboboxChipsInput />
              </React.Fragment>
            )}
          </ComboboxValue>
        </ComboboxChips>
        <ComboboxContent anchor={anchor}>
          <ComboboxEmpty>No items found.</ComboboxEmpty>
          <ComboboxList>
            {(item) => (
              <ComboboxItem key={item} value={item}>
                {item}
              </ComboboxItem>
            )}
          </ComboboxList>
        </ComboboxContent>
      </Combobox>
    </div>
  );
}
