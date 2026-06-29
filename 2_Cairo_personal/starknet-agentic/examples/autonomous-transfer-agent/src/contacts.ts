import fs from "node:fs";
import path from "node:path";

import { resolveAgentRoot } from "./paths.js";
import type { AgentConfig } from "./types.js";

export interface ContactsFile {
  agentName?: string;
  contacts: Record<string, string>;
}

export function resolveContactsPath(explicit?: string): string {
  if (explicit) return path.resolve(explicit);
  const fromEnv = process.env.CONTACTS_PATH;
  if (fromEnv) return path.resolve(fromEnv);
  const local = path.join(resolveAgentRoot(), "contacts.json");
  if (fs.existsSync(local)) return local;
  return path.join(resolveAgentRoot(), "contacts.example.json");
}

export function loadContacts(contactsPath?: string): ContactsFile | null {
  const resolved = resolveContactsPath(contactsPath);
  if (!fs.existsSync(resolved)) return null;

  const raw = JSON.parse(fs.readFileSync(resolved, "utf8")) as ContactsFile;
  if (!raw.contacts || typeof raw.contacts !== "object") {
    throw new Error("contacts file must have a contacts object");
  }
  return raw;
}

export function resolveContactAddress(
  contacts: ContactsFile,
  name: string,
): string {
  const key = name.trim().toLowerCase();
  const address = contacts.contacts[key] ?? contacts.contacts[name.trim()];
  if (!address) {
    const available = Object.keys(contacts.contacts).join(", ");
    throw new Error(
      `Contact "${name}" not found. Available: ${available || "(none)"}`,
    );
  }
  return address;
}

export function applyContactToConfig(
  config: AgentConfig,
  contacts: ContactsFile,
  contactName: string,
  amountOverride?: string,
): AgentConfig {
  const recipient = resolveContactAddress(contacts, contactName);
  return {
    ...config,
    transfer: {
      ...config.transfer,
      recipient,
      ...(amountOverride ? { amount: amountOverride } : {}),
    },
  };
}
