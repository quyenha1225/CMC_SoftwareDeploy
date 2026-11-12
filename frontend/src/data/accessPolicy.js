import { MENU } from "../components/layout/navigation.js";

// UI navigation only. Real authorization must be enforced by the API.
export function canViewPage(role, page) {
  if (!Object.hasOwn(MENU, role)) return false;
  if (role === "student" && page === "payment") return true;
  return MENU[role].some(([, id, , children]) => id === page || children?.some(([, child]) => child === page));
}
