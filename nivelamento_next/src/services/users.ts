/* eslint-disable @typescript-eslint/no-unused-vars */
const url: string = "https://jsonplaceholder.typicode.com/users";

export async function getUsers() {
    try {
        const response = await fetch(url);

        if(!response.ok) {
            throw new Error("Não foi possível obter os usuários");
        }

        const usuariosJson = await response.json();

        return usuariosJson;
    }catch (error) {
        throw new Error("Erro ao obter usuários");
    }
}