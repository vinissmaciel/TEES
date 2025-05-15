interface MenuItemProps{
    item: string
}

export default function MenuItem(props: MenuItemProps) {
    return(
        <p>
            {props.item}
        </p>
    )
}