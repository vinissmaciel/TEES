import Link from "next/link";
import MenuItem from "./MenuItem";

export default function MenuLateral() {
    return(
        <div className="bg-sky-400 p-4 h-full w-[200px]">

            <Link href="/item1">
                <MenuItem item="Item 1" />
            </Link>

            <Link href="/item2">
                <MenuItem item="Item 2" />
            </Link>

            <Link href="/item3">
                <MenuItem item="Item 3" />
            </Link>
        </div>
    )
}