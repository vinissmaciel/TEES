#CRIAÇÃO DAS TABELAS
CREATE TABLE author(
   id SERIAL PRIMARY KEY,
   name TEXT NOT NULL
);

CREATE TABLE post(
   id SERIAL PRIMARY KEY,
   title TEXT NOT NULL,
   content TEXT NOT NULL,
   author_id INT NOT NULL references author(id)
);

CREATE TABLE tag(
   id SERIAL PRIMARY KEY,
   name TEXT NOT NULL
);

CREATE TABLE posts_tags(
   post_id INT NOT NULL references post(id),
   tag_id INT NOT NULL references tag(id)
 );

#INSERÇÃO DOS VALORES
INSERT INTO author (id, name)
VALUES (1, 'Pete Graham'),
   	(2, 'Rachid Belaid'),
   	(3, 'Robert Berry');

INSERT INTO tag (id, name)
VALUES (1, 'scifi'),
   	(2, 'politics'),
   	(3, 'science');

INSERT INTO post (id, title, content, author_id)
VALUES (1, 'Endangered species',
    	'Pandas are an endangered species', 1 ),
   	(2, 'Freedom of Speech',
    	'Freedom of speech is a necessary right', 2),
   	(3, 'Star Wars vs Star Trek',
    	'Few words from a big fan', 3);

INSERT INTO posts_tags (post_id, tag_id)
VALUES (1, 3),
   	(2, 2),
   	(3, 1);
   	
   	


#CRIANDO OS DOCUMENTOS COM TITULO, CONTEUDO, AUTOR, TAGS
SELECT post.title || ' ' || post.content || ' ' ||
   	 author.name || ' ' ||
   	 coalesce((string_agg(tag.name, ' ')), '') as document  #CASO TENHA VÁRIAS TAGS, O string_agg() CONCATENA
FROM post
   	 JOIN author ON author.id = post.author_id 
		 JOIN posts_tags ON posts_tags.post_id = post.id
   	 JOIN tag ON tag.id = posts_tags.tag_id 
GROUP BY post.id, author.id;
		 



#TRANSFORMOU O DOCUMENTO PARA FORMATO TSVECTOR (lista ordenada de lexemas distintos o qual são palavras que foram normalizadas para fazer variações diferentes de uma mesma palavra e que são parecidas)
SELECT to_tsvector(post.title) ||
    to_tsvector(post.content) ||
    to_tsvector(author.name) ||
    to_tsvector(coalesce((string_agg(tag.name, ' ')), '')) as document
FROM post
    JOIN author ON author.id = post.author_id 
	 JOIN posts_tags ON posts_tags.post_id = post.id
    JOIN tag ON tag.id = posts_tags.tag_id
GROUP BY post.id, author.id;


#EXEMPLO TSVECTOR
SELECT to_tsvector('Try not to become a man of success, but rather try to become a man of value');


#EXEMPLOS CONSULTA TSVECTOR
select to_tsvector('If you can dream it, you can do it') @@ 'dream';
select to_tsvector('It''s kind of fun to do the impossible') @@ 'impossible';

#EXEMPLO TSQUERY (criará os mesmos lexemas e que ao utilizar o operador @@, transformará(cast) a string em um formato tsquery)
SELECT 'impossible'::tsquery, to_tsquery('impossible');
SELECT 'dream'::tsquery, to_tsquery('dream');
SELECT to_tsvector('It''s kind of fun to do the impossible') @@ to_tsquery('impossible');


#EXEMPLO TSQUERY COM OPERADORES LOGICOS
SELECT to_tsvector('If the facts don''t fit the theory, change the facts') @@ to_tsquery('! fact');
SELECT to_tsvector('If the facts don''t fit the theory, change the facts') @@ to_tsquery('theory & !fact');
SELECT to_tsvector('If the facts don''t fit the theory, change the facts.') @@ to_tsquery('fiction | theory');

#EXEMPLO USO CORINGA *
SELECT to_tsvector('If the facts don''t fit the theory, change the facts.') @@ to_tsquery('theo:*');



#COMO FAZER CONSULTAS NOS DOCUMENTOS
SELECT pid, p_title
FROM (SELECT post.id as pid,
         	post.title as p_title,
         	to_tsvector(post.title) ||
         	to_tsvector(post.content) ||
         	to_tsvector(author.name) ||
         	to_tsvector(coalesce(string_agg(tag.name, ' '))) as document
	  	FROM post
		  	JOIN author ON author.id = post.author_id
		  	JOIN posts_tags ON posts_tags.post_id = post.id
		  	JOIN tag ON tag.id = posts_tags.tag_id
	  	GROUP BY post.id, author.id) p_search
WHERE p_search.document @@ to_tsquery('Endangered & Species');


#EXEMPLO UTILIZAÇÃO DE IDIOMAS
SELECT to_tsvector('english', 'We are running');
SELECT to_tsvector('french', 'We are running');

#ADICIONANDO COLUNA DE IDIOMA NO POST PARA TRABALHAR COM VÁRIOS IDIOMAS
ALTER TABLE post ADD language text NOT NULL DEFAULT('english');

#RECONSTRUINDO OS DOCUMENTOS COM A NOVA COLUNA DE IDIOMA
SELECT to_tsvector(post.language::regconfig, post.title) ||
   	to_tsvector(post.language::regconfig, post.content) ||
   	to_tsvector('simple', author.name) ||
   	to_tsvector('simple', coalesce((string_agg(tag.name, ' ')), '')) as document
FROM post
	JOIN author ON author.id = post.author_id
	JOIN posts_tags ON posts_tags.post_id = post.id
	JOIN tag ON tag.id = posts_tags.tag_id
GROUP BY post.id, author.id;

#EXEMPLO DICIONÁRIO SIMPLE (não ignora stop words e não tenta encontrar fonemas(stem) de uma palavra)
SELECT to_tsvector('simple', 'We are running');

#EXEMPLO UNACCENT
CREATE EXTENSION unaccent;
SELECT unaccent('èéêë');

#INSERENDO CONTEÚDO ACENTUADO NA TABELA DE POSTS
INSERT INTO post (id, title, content, author_id, language)
VALUES (4, 'il était une fois', 'il était une fois un hôtel ...', 2,'french')



#IGNORANDO ACENTOS NA CRIANÇÃO DOS DOCUMENTOS (NÃO RECOMENDADO POIS CONSUME MUITO DO SERVIDOR)
SELECT to_tsvector(post.language, unaccent(post.title)) ||
   	to_tsvector(post.language, unaccent(post.content)) ||
   	to_tsvector('simple', unaccent(author.name)) ||
   	to_tsvector('simple', unaccent(coalesce(string_agg(tag.name, ' '))))
FROM post
	JOIN author ON author.id = post.author_id
	JOIN posts_tags ON posts_tags.post_id = post.id
	JOIN tag ON author.id = post.author_id
GROUP BY p.id


#CONSTRUINDO UMA NOVA CONFIGURAÇÃO DE BUSCA TEXTUAL EM FRANCES COM SUPORTE A CARACTERES NAO ACENTUADOS (RETORNA O MESMO RESULTADO DO UNACCENT)
CREATE TEXT SEARCH CONFIGURATION fr ( COPY = french );
ALTER TEXT SEARCH CONFIGURATION fr ALTER MAPPING
FOR hword, hword_part, word WITH unaccent, french_stem;

SELECT to_tsvector('french', 'il était une fois');
SELECT to_tsvector('fr', 'il était une fois');
SELECT to_tsvector('fr', 'Hôtel') @@ to_tsquery('hotels') as result;


#CRIANDO CONFIGURAÇÕES PARA TODOS OS IDIOMAS NO OUTRO ARQUIVO idiomas.sql MENOS FR
UPDATE post
SET LANGUAGE = 'en'
WHERE LANGUAGE = 'english';

UPDATE post
SET LANGUAGE = 'fr'
WHERE LANGUAGE = 'french';

#BUSCANDO DE ACORDO COM A RELEVANCIA SETWEIGHT (permite atribuir um valor de peso para um tsvector. O valor pode ser 'A', 'B', 'C' ou 'D'.) TS_RANK (retorna um número flutuante que representa a relevância deste documento em relação a consulta)
SELECT pid, p_title
FROM (SELECT post.id as pid,
         	post.title as p_title,
         	setweight(to_tsvector(post.language::regconfig, post.title), 'A') ||
         	setweight(to_tsvector(post.language::regconfig, post.content), 'B') ||
         	setweight(to_tsvector('simple', author.name), 'C') ||
	         	setweight(to_tsvector('simple', coalesce(string_agg(tag.name, ' '))), 'B') as document
	  	FROM post
		  	JOIN author ON author.id = post.author_id
		  	JOIN posts_tags ON posts_tags.post_id = post.id
		  	JOIN tag ON tag.id = posts_tags.tag_id
	  	GROUP BY post.id, author.id) p_search
WHERE p_search.document @@ to_tsquery('english', 'Endangered & Species')
ORDER BY ts_rank(p_search.document, to_tsquery('english', 'Endangered & Species')) DESC;


#EMEMPLOS ts_rank
SELECT ts_rank(to_tsvector('This is an example of document'), to_tsquery('example | document')) as relevancy;
SELECT ts_rank(to_tsvector('This is an example of document'), to_tsquery('example ')) as relevancy;
SELECT ts_rank(to_tsvector('This is an example of document'), to_tsquery('example | unkown')) as relevancy;
SELECT ts_rank(to_tsvector('This is an example of document'), to_tsquery('example & document')) as relevancy;
SELECT ts_rank(to_tsvector('This is an example of document'), to_tsquery('example & unknown')) as relevancy;

#CRIANDO INDICE DO TIPO GIN
CREATE INDEX idx_fts_post ON post
USING gin(setweight(to_tsvector(language, title),'A') ||
   	setweight(to_tsvector(language, content), 'B'));

#CRIANDO VISÃO MATERIALIZADA
CREATE MATERIALIZED VIEW search_index AS
SELECT post.id,
   	post.title,
   	setweight(TO_TSVECTOR(('public.' || post.language)::regconfig, post.title), 'A') ||
   	setweight(to_tsvector(('public.' || post.language)::regconfig, post.content), 'B') ||
   	setweight(to_tsvector('simple', author.name), 'C') ||
   	setweight(to_tsvector('simple', coalesce(string_agg(tag.name, ' '))), 'A') as document
FROM post
	JOIN author ON author.id = post.author_id
	JOIN posts_tags ON posts_tags.post_id = post.id
	JOIN tag ON tag.id = posts_tags.tag_id
GROUP BY post.id, author.id


#ADICIONANDO INDICIE NA VISÃO MATERIALIZADA
CREATE INDEX idx_fts_search ON search_index USING gin(document);

#CONSULTA MAIS SIMPLES COM A VISÃO MATEARILIZADA
SELECT id as post_id, title
FROM search_index
WHERE document @@ to_tsquery('en', 'Endangered & Species')
ORDER BY ts_rank(document, to_tsquery('en', 'Endangered & Species')) DESC;

#EXEMPLOS ERROS DE ORTOGRAFIA
CREATE EXTENSION pg_trgm;
SELECT similarity('Something', 'something');
SELECT similarity('Something', 'samething');
SELECT similarity('Something', 'unrelated');
SELECT similarity('Something', 'everything');
SELECT similarity('Something', 'omething');

#CRIANDO LISTA DE LEXEMAS EXCLUSIVOS USADOS PELOS DOCUMENTOS PARA PODERMOS CONSIDERAR ERROS ORTOGRAFICOS COM SIMILARIDADE > 0.5
CREATE MATERIALIZED VIEW unique_lexeme AS
SELECT word
FROM ts_stat('
    SELECT
        to_tsvector(''simple'', post.title) ||
        to_tsvector(''simple'', post.content) ||
        to_tsvector(''simple'', author.name) ||
        to_tsvector(''simple'', coalesce(string_agg(tag.name, '' '')))
    FROM public.post
        JOIN public.author ON author.id = post.author_id
        JOIN public.posts_tags ON posts_tags.post_id = post.id
        JOIN public.tag ON tag.id = posts_tags.tag_id
    GROUP BY post.id, author.id
');

#CRIAÇÃO DO INDICIE DOS LEXEMAS EXCLUSIVOS
CREATE INDEX words_idx ON unique_lexeme USING gin(word gin_trgm_ops);

SELECT word
FROM unique_lexeme
WHERE similarity(word, 'spech') > 0.5
ORDER BY word <-> 'spech'
LIMIT 1;
