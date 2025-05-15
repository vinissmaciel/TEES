/* eslint-disable @typescript-eslint/no-unused-vars */
"use client"

import { getUsers } from "@/services/users";
import { useEffect, useState } from "react";

export default function Item1() {

    const [usuarios, setUsuarios] = useState([]);

    async function obterUsuarios() {
        const u = await getUsers();
        setUsuarios(u);
    }

    useEffect(() => {
        obterUsuarios();
    }, []);

    return(
        <div className="p-4">
            {
                usuarios && (
                    <ul>
                        {usuarios.map((u) => (
                            <li key={u.id}>
                                ID: {u.id} <br />
                                Nome: {u.name} <br />
                                Email: {u.email} <br />
                                Cidade: {u.address.city} <br />
                                Rua: {u.address.street} <br />
                                -----------------------------------
                                <br />
                            </li>
                        ))}
                    </ul>
                )
            }
        </div>
    )
}